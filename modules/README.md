# Módulos reutilizables

Módulos internos que encapsulan los patrones repetidos de la arquitectura. No configuran
proveedores ni backend; los proyectos de `projects/` los consumen mediante rutas relativas.

| Módulo                   | Recursos                                                                 | Consumido por |
|--------------------------|--------------------------------------------------------------------------|---------------|
| `virtual-network`        | `azurerm_virtual_network`, `azurerm_subnet` (mapa de subredes con delegaciones y políticas) | `01-network` |
| `network-security-group` | `azurerm_network_security_group`, `azurerm_network_security_rule`, asociación con subredes | `01-network` |
| `private-dns-zone`       | `azurerm_private_dns_zone`, `azurerm_private_dns_zone_virtual_network_link` | `01-network` |

## Convenciones

- Las colecciones se reciben como `map(object)` indexados por un **alias estable** (`app`, `db`,
  `vm`, ...). Usar `for_each` sobre claves estables evita que Terraform recree recursos
  cuando se agrega o elimina un elemento intermedio, como ocurriría con `count`.
- Las entradas se validan con bloques `validation` para detectar errores en el `plan` y no en
  la API de Azure.
- Cada módulo declara `required_providers` con la misma restricción de versión que los proyectos.
