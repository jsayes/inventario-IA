# ============================================================================
#  Atajos. Todo corre dentro del contenedor `tools` (Terraform, tflint,
#  checkov, awscli y pytest ya instalados).
# ============================================================================
TOOLS  := docker compose run --rm tools
LOCAL  := infra/envs/local
PROD   := infra/envs/prod

.PHONY: up down shell test fmt validate lint seguridad plan-local apply-local \
        destroy-local invocar-salud muestras smoke validar-prod

up:            ## Levanta LocalStack y construye la imagen de herramientas
	docker compose up -d localstack
	docker compose build tools

down:          ## Apaga todo y borra el estado de LocalStack
	docker compose down -v

shell:         ## Terminal dentro del contenedor de herramientas
	$(TOOLS) bash

test:          ## Pruebas unitarias
	$(TOOLS) pytest -q

fmt:           ## Formato de Terraform (falla si algo no está formateado)
	$(TOOLS) terraform fmt -check -recursive infra

validate:      ## terraform validate de local y prod (sin backend)
	$(TOOLS) bash -c "cd $(LOCAL) && terraform init -backend=false -input=false >/dev/null && terraform validate"
	$(TOOLS) bash -c "cd $(PROD)  && terraform init -backend=false -input=false >/dev/null && terraform validate"

lint:          ## tflint sobre todos los módulos y entornos
	$(TOOLS) bash -c "tflint --init && tflint --recursive"

seguridad:     ## Análisis estático de seguridad
	$(TOOLS) checkov -d infra --quiet --compact

plan-local:
	$(TOOLS) bash -c "cd $(LOCAL) && terraform init -input=false && terraform plan"

apply-local:
	$(TOOLS) bash -c "cd $(LOCAL) && terraform init -input=false && terraform apply -auto-approve"

destroy-local:
	$(TOOLS) bash -c "cd $(LOCAL) && terraform destroy -auto-approve"

invocar-salud: ## Comprueba que la Lambda de ejemplo responde
	$(TOOLS) bash -c "aws lambda invoke --function-name inv-local-salud /tmp/out.json >/dev/null && cat /tmp/out.json && echo"

muestras:      ## Sube los archivos de data/muestras al bucket landing
	$(TOOLS) bash scripts/subir_muestras.sh

smoke:         ## Prueba de humo de punta a punta
	$(TOOLS) bash scripts/smoke_test.sh

validar-prod:  ## Solo validate de prod (no se aplica en esta prueba)
	$(TOOLS) bash -c "cd $(PROD) && terraform init -backend=false -input=false >/dev/null && terraform validate"
