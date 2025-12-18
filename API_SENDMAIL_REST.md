# Sendmail API REST
Servicio apirest disponible para el envío y consulta de correos.

## Endpoints
- POST /Sendmail · Envía un correo electrónico.
- GET /Sendmail/:uniqueId · Devuelve la auditoría del envío. `uniqueId` es el Guid que devuelve el POST.
- GET /Sendmail (beta) · Devuelve el estatus del servicio.

## POST /Sendmail (envío de correo)
- La dirección de origen (From) se toma de la asociada al API key utilizado.

### Parámetros
| Parámetro | Descripción |
| --- | --- |
| Authorization | Autenticación básica `Basic apikey:apikeytoken`. |
| o:dryrun | `[true|false]` Si está activo no se entrega al SMTP (útil en validación y pruebas). Se puede enviar en query string o en el cuerpo. |
| To | Dirección de correo válida o lista separada por comas. |
| cc | Direcciones de email en copia. |
| bcc | Direcciones de email en copia oculta. |
| h:Reply-To | Dirección que usará el cliente al responder. |
| h:Return-Receipt-To | Dirección que usará el cliente para acuse de recibo. |
| h:Disposition-Notification-To | Dirección que usará el cliente para notificación de apertura. |
| subject | Asunto del email. Se sustituyen `\r` y `\n` por espacio. Si supera la longitud máxima se trunca y añade `...`; se recomienda cortar en el cliente. |
| html | Cuerpo en HTML. |
| text | Cuerpo en texto plano. Si se envían ambos, el cliente mostrará uno u otro según soporte (se recomienda solo `html`). |
| attachment | Archivos adjuntos. Enviar el POST como `multipart/form-data`. |

### Respuestas
| Status | Éxito | Descripción |
| --- | --- | --- |
| 201 Created | Sí | Devuelve el identificador del envío. La cabecera `Location` coincide con `links.self.href`. |
| 400 BadRequest | No | Cuerpo no parseable o límites superados. |
| 403 Forbidden | No | Falta o es inválido el token del API key. |
| 502 BadGateway | No | Error al entregar el correo al servidor SMTP. |
| 500 InternalServerError | No | Error genérico no controlado. |

Ejemplo 201:

```json
{
    "success": "true",
    "message": "",
    "sendMailUniqueId": "00000000000000000000000000000001",
    "links": {
        "self": {
            "href": "https://val-backend.admon-cfnavarra.es/wsEnvioCorreos/SendMail/00000000000000000000000000000001"
        }
    }
}
```

Ejemplo 400:

```json
{
    "success": "false",
    "message": "causa"
}
```

Posibles mensajes de error:
- Error parsing request: To invalid mail address
- Missing from in mail, application has no set defaultfrom you must specify in request
- Invalid from domain invalido.es not in application valid from domains: 'navarra.es,admon-cfnavarra.es'
- Invalid from domain invaido.ex not in default valid domains: 'navarra.es,admon-cfnavarra.es'
- Invalid mail missging to or cc or bcc
- Invalid mail attachment size {attachmentsSize} bytes exceeded max for applicattion {grant.EmailAttachmentsMaxSize} bytes
- Invalid mail attachment size {attachmentsSize} exceeded max for server {Configuracion.MaxBytes} bytes

Ejemplo 403 / 502 / 500 (mismo formato, distinto status):

```json
{
    "success": "false",
    "message": "causa"
}
```

## GET /Sendmail/:uniqueId (consulta de envío)
- Devuelve la auditoría del envío asociado al `uniqueId`.

Ejemplo de respuesta:

```json
{
    "uniqueId": "000000000-0000-0000-0000-000000000001",
    "entryPoint": "Apirest",
    "dryrun": false,
    "applicationId": 1,
    "grantId": 1,
    "deliveryServerUrl": "smtp://SVC_PRUEBA:***************@mail.admon-cfnavarra.es:25/",
    "localIp": "127.0.0.1",
    "remoteIp": "127.0.0.1",
    "forwardedForIp": null,
    "tags": "",
    "fail": false,
    "failReason": null,
    "startAt": "2024-01-15T12:20:29.619",
    "elpased": 0.3966694,
    "from": "from.ejemplo@navarra.es",
    "to": "to.ejemplo@navarra.es",
    "cc": "",
    "bcc": "",
    "subjectLength": 95,
    "bodyLength": 101,
    "attachmentsCount": 0,
    "attachmentsSize": 0
}
```
    "bcc":"",

    "subjectLength":95,
