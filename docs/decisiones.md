# Registro de decisiones de arquitectura (ADR)

Cada decisión técnica relevante se documenta con su contexto, la alternativa elegida y sus
consecuencias, siguiendo el formato *Architecture Decision Record*.

---

## ADR-001 · Adoptar la infraestructura existente mediante `import`

**Estado:** aceptada

**Contexto.** La arquitectura de referencia ya fue desplegada manualmente desde el portal de Azure
en el grupo de recursos `rg-utvt-integradora-dev-mxc-001`. Los nombres de PostgreSQL, la cuenta de
almacenamiento y la Web App son globalmente únicos, y Azure puede retenerlos temporalmente después
de eliminarlos.

**Decisión.** Usar bloques `import` (Terraform ≥ 1.5) para incorporar los recursos existentes al
estado de Terraform y declarar como código lo que falta del diagrama (NSG, identidades
administradas, RBAC). Una vez adoptados, los bloques `import` se retiran para que el código pueda
desplegar un entorno nuevo desde cero.

**Consecuencias.**
- No hay pérdida de datos ni tiempo de inactividad y se conservan los nombres de la tabla de diseño.
- El código debe reflejar con exactitud la configuración real para que el `plan` no proponga
  cambios no deseados; cada diferencia se revisa antes de aplicar.
- Los atributos inmutables (*ForceNew*) que difieren del diseño provocan el reemplazo del recurso,
  lo cual se documenta explícitamente en el plan correspondiente.

---

## ADR-002 · Proyectos por capas con estado remoto en Azure Storage

**Estado:** aceptada

**Contexto.** La práctica pide generar el número de proyectos que se considere pertinente. Un único
estado para toda la infraestructura amplía el impacto de cualquier error y obliga a planear todos
los recursos en cada cambio.

**Decisión.** Separar la infraestructura en proyectos (*root modules*) según su ciclo de vida:

| Proyecto       | Responsabilidad                                                   |
|----------------|-------------------------------------------------------------------|
| `00-bootstrap` | Cuenta de almacenamiento y contenedor para el estado remoto       |
| `01-network`   | Grupo de recursos, VNet, subredes, NSG y zonas DNS privadas       |
| `02-data`      | PostgreSQL Flexible Server, Storage Account y Private Endpoints   |
| `03-compute`   | App Service, VM Linux worker, Azure Bastion e identidades/RBAC    |

Cada proyecto guarda su estado en el backend `azurerm`, que ofrece bloqueo nativo mediante
*blob leases* y autenticación con Microsoft Entra ID (sin llaves de acceso). Las capas superiores
consumen las salidas de las inferiores con `terraform_remote_state`. Los patrones repetidos (NSG,
zona DNS privada, Private Endpoint) se encapsulan en módulos reutilizables en `modules/`.

**Consecuencias.**
- Un cambio en la capa de cómputo no puede afectar el estado de la red ni de los datos.
- Las capas se aplican en orden: `00` → `01` → `02` → `03`.
- El estado de `00-bootstrap` se migra a su propio contenedor una vez creado.

---

## ADR-003 · La tabla de diseño prevalece sobre las etiquetas del diagrama

**Estado:** aceptada

**Contexto.** El diagrama usa nombres genéricos (`vnet-lz-prod`, `snet-app`, `nsg-db`) que no
coinciden con los nombres definidos en la tabla de diseño ni con los desplegados.

**Decisión.** Usar los nombres de la tabla de diseño. Los recursos que no aparecen en la tabla
conservan su nombre actual si ya existen, y los nuevos siguen la convención CAF. El detalle está en
[nomenclatura.md](nomenclatura.md).

---

## ADR-004 · Segmentación con un NSG por subred y denegación por defecto

**Estado:** aceptada

**Contexto.** El diagrama asigna un NSG a cada subred, pero el despliegue manual solo tenía el NSG
que el portal crea por defecto en la NIC de la VM, sin reglas.

**Decisión.**
- Un NSG por subred que permite únicamente los flujos 2–5 del diagrama y la administración por
  Bastion, con `DenyAllInbound` (4096) y, en las subredes de origen, `DenyVirtualNetworkOutbound`
  (4000) para impedir el movimiento lateral.
- Habilitar `private_endpoint_network_policies = NetworkSecurityGroupEnabled` en las subredes de
  Private Endpoints; con el valor predeterminado (`Disabled`), los NSG no se aplican al tráfico
  hacia los endpoints.
- El NSG de `AzureBastionSubnet` incluye las ocho reglas obligatorias de Azure Bastion, de modo
  que la subred queda lista para un SKU dedicado.

**Consecuencias.** Cualquier flujo nuevo requiere una regla explícita en `projects/01-network/nsg.tf`.

---

## ADR-005 · Azure Bastion Developer y subred reservada

**Estado:** aceptada

**Contexto.** El diagrama ubica Azure Bastion en `AzureBastionSubnet`. El SKU Basic cuesta cerca de
US$140 al mes, más que el crédito mensual de Azure for Students. El SKU Developer no tiene costo,
pero no se despliega en la subred: usa infraestructura compartida y se conecta a las VM desde la IP
de plataforma `168.63.129.16`.

**Decisión.** Conservar Bastion Developer y mantener `AzureBastionSubnet` con el tamaño `/24` de la
tabla de diseño, con su NSG, reservada para una futura migración a un SKU dedicado. El NSG de la VM
permite SSH tanto desde `168.63.129.16/32` (Developer) como desde `10.0.5.0/24` (dedicado).

**Consecuencias.** Bastion Developer admite una sola sesión simultánea y no soporta *peering*; si el
proyecto lo requiere, basta con cambiar el SKU y agregar la IP pública en `03-compute`.
