# CyberMAX MCP Server - Hello World

Servidor Model Context Protocol (MCP) para integración con CyberMAX ERP y Claude Code.

## Descripción

Este es un servidor MCP básico implementado en Delphi que proporciona herramientas de ejemplo para la integración con Claude Code. Utiliza el repositorio base [Delphi-MCP-Server](https://github.com/GDKsoftware/delphi-mcp-server) y extiende su funcionalidad con herramientas específicas para CyberMAX.

## Estructura del Proyecto

```
/mnt/w/MCPServer/
├── CyberMaxHelloMCP.dpr     # Proyecto principal
├── CyberMaxHelloMCP.exe     # Ejecutable compilado
├── settings.ini              # Configuración del servidor
├── README.md                 # Esta documentación
└── Tools/                    # Herramientas MCP personalizadas
    ├── MCPServer.Tool.HelloCyberMax.pas
    ├── MCPServer.Tool.CyberEcho.pas
    └── MCPServer.Tool.CyberTime.pas
```

## Herramientas Disponibles

### 1. hello_cybermax
Devuelve un mensaje de bienvenida e información sobre los módulos de CyberMAX disponibles.

**Parámetros:** Ninguno

**Ejemplo de respuesta:**
```
¡Hola desde CyberMAX MCP Server!
Server Version: 1.0.0
Available CyberMAX Modules:
  - TCConta (Contabilidad/Accounting)
  - Gestion2000 (Ventas y Compras/Sales & Purchasing)
  - Almacen (Warehouse Management)
  ...
```

### 2. cyber_echo
Devuelve el mensaje enviado, opcionalmente en mayúsculas.

**Parámetros:**
- `message` (string, requerido): El mensaje a devolver
- `uppercase` (boolean, opcional): Si true, devuelve el mensaje en mayúsculas

**Ejemplo de uso:**
```json
{
  "message": "Hola desde Claude Code",
  "uppercase": false
}
```

### 3. cyber_time
Devuelve la hora actual del sistema con formato personalizable.

**Parámetros:**
- `format` (string, opcional): Formato de fecha/hora (default: "yyyy-mm-dd hh:nn:ss")
- `includemilliseconds` (boolean, opcional): Incluir milisegundos
- `timezone` (string, opcional): Offset de zona horaria (ej: "+2", "-5")

**Ejemplo de respuesta:**
```
Current Time: 2025-09-03 13:17:43
Date: miércoles, septiembre 3, 2025
Time: 01:17:43 PM
ISO 8601: 2025-09-03T13:17:43
Unix Timestamp: 1756905463
```

## Configuración del Servidor

### settings.ini
```ini
[Server]
Port=3001
Host=localhost
Transport=http
MaxConnections=10
AllowedOrigins=http://localhost,http://127.0.0.1,https://localhost,https://127.0.0.1

[Logging]
LogLevel=INFO
LogFile=mcp_server.log
ConsoleLog=True

[MCP]
ProtocolVersion=2024-11-05
ServerName=CyberMAX MCP Server
ServerVersion=1.0.0
```

**Nota importante:** El puerto por defecto es 3001 (cambiado desde 3000 para evitar conflictos).

## Compilación

### Prerrequisitos
- RAD Studio 12 (Delphi 29.0)
- Repositorio base Delphi-MCP-Server clonado en `/mnt/w/Delphi-MCP-Server`
- TaurusTLS_RT en los runtime packages

### Compilar el proyecto
Para compilar, solicitar a Claude Code que use el compiler-agent con el archivo de proyecto:
```
Compilar CyberMaxHelloMCP.dproj
```

El compiler-agent se encargará de ejecutar el compilador Delphi con la configuración correcta.

**Nota:** 
- El compiler-agent requiere el archivo .dproj (proyecto), no el .dpr
- No intentar usar dcc32 directamente desde WSL, ya que no funcionará
- Desde Windows sí se puede usar dcc32 directamente si se prefiere

## Ejecución del Servidor

### Desde Windows
```batch
cd W:\MCPServer
CyberMaxHelloMCP.exe
```

### Desde WSL
```bash
cd /mnt/w/MCPServer
./CyberMaxHelloMCP.exe
```

El servidor mostrará:
```
[INFO] Starting CyberMAX MCP Server...
[INFO] Listening on port 3001
[INFO] MCP Server started on http://localhost:3001
Server started successfully!

Available tools:
  - hello_cybermax : Get greeting and CyberMAX info
  - cyber_echo     : Echo back your message
  - cyber_time     : Get current system time

Press CTRL+C to stop...
```

## Configuración en Claude Code

### 1. Determinar la IP del Sistema Windows

Desde WSL, ejecutar:
```bash
ip route | grep default | awk '{print $3}'
# O verificar con: hostname -I
```

En este caso, la IP es: `192.168.0.89`

### 2. Configurar Claude Code

El servidor MCP utiliza transporte HTTP con el endpoint `/mcp`. Claude Code requiere configuración mediante línea de comandos.

#### Método recomendado - Comando `mcp add`:
```bash
claude mcp add cybermax-hello http://192.168.0.89:3001/mcp --scope user -t http
```

**Parámetros importantes:**
- `cybermax-hello`: Nombre del servidor MCP
- `http://192.168.0.89:3001/mcp`: URL completa con endpoint
- `--scope user`: Alcance de configuración (user, project, o local)
- `-t http`: Tipo de transporte HTTP (obligatorio para servidores remotos)

#### Método alternativo - Comando interactivo `/config`:
```bash
# Dentro de Claude Code, usar:
/config

# Luego añadir manualmente el servidor
```

**Notas importantes:** 
- El flag `--mcp-config` tiene un bug conocido en la versión v1.0.73 y no funciona correctamente
- Para servidores HTTP remotos, SIEMPRE especificar `-t http`
- Debe usar el endpoint `/mcp` (no solo la IP y puerto)
- El formato correcto es: `http://IP:PUERTO/mcp`

### 3. Verificar la Conexión

Una vez configurado, las herramientas aparecerán con el prefijo `mcp__cybermax-hello__`:
- `mcp__cybermax-hello__hello_cybermax`
- `mcp__cybermax-hello__cyber_echo`
- `mcp__cybermax-hello__cyber_time`

Para verificar que el servidor está disponible:
```bash
# Listar servidores MCP configurados
claude mcp list

# O dentro de Claude Code
/mcp
```

## Arquitectura Técnica

### Patrón de Herramientas

Cada herramienta sigue este patrón:

1. **Clase de Parámetros** (TToolParams)
   ```pascal
   TCyberEchoParams = class
     property Message: string;
     property UpperCase: Boolean;
   end;
   ```

2. **Clase de Herramienta** (TMCPToolBase<TParams>)
   ```pascal
   TCyberEchoTool = class(TMCPToolBase<TCyberEchoParams>)
     function ExecuteWithParams(const Params: TCyberEchoParams): string;
   end;
   ```

3. **Registro Automático**
   ```pascal
   initialization
     TMCPRegistry.RegisterTool('cyber_echo', 
       function: IMCPTool
       begin
         Result := TCyberEchoTool.Create;
       end
     );
   ```

### Manejo de Errores

El servidor implementa manejo robusto de errores:
- Validación de parámetros antes de procesamiento
- Inicialización explícita de valores opcionales en constructores
- Uso directo de propiedades sin complejidad innecesaria

Ejemplo correcto en cyber_echo:
```pascal
// Inicialización en constructor
constructor TCyberEchoParams.Create;
begin
  inherited;
  FMessage := '';
  FUpperCase := False;  // Explícito aunque Delphi lo inicializa a False
end;

// Uso directo y simple de la propiedad
if Params.UpperCase then
  ProcessedMessage := System.SysUtils.UpperCase(Params.Message)
else
  ProcessedMessage := Params.Message;
```

**Nota importante:** 
- No usar try-except para leer propiedades simples
- No copiar valores de propiedades a variables locales sin necesidad
- Delphi inicializa automáticamente: Boolean→False, Integer→0, String→''

## Solución de Problemas

### Puerto en Uso
Si el puerto 3001 está en uso:
1. Cambiar en `settings.ini`
2. Actualizar la configuración en Claude Code

### Access Violation
Si aparecen errores de Access Violation:
1. Verificar inicialización de parámetros opcionales
2. Añadir constructores con valores por defecto
3. Implementar manejo defensivo de propiedades

### Servidor No Visible en Claude Code
1. Verificar que usa transporte HTTP (no stdio)
2. Confirmar endpoint `/mcp`
3. Usar IP del sistema Windows, no localhost desde WSL
4. Verificar firewall de Windows

### Proceso Colgado
```bash
# Desde WSL
taskkill.exe /IM CyberMaxHelloMCP.exe /F

# O buscar y matar el proceso
ps aux | grep CyberMax
kill -9 [PID]
```

## Logs y Depuración

Los logs del servidor muestran:
- Inicialización y configuración
- Cada request JSON-RPC recibido
- Session ID de Claude Code
- Respuestas enviadas
- Errores y excepciones

Ejemplo de log:
```
[2025-09-03 13:17:14.906] [INFO ] Request: {"method":"tools/call","params":{"name":"cyber_echo",...}}
[2025-09-03 13:17:14.906] [INFO ] Session ID from header: {ADB063D4-752F-4795-A98D-0E843FDF2AA4}
[2025-09-03 13:17:14.906] [INFO ] MCP CallTool called for tool: cyber_echo
[2025-09-03 13:17:14.906] [INFO ] Response: {"jsonrpc":"2.0","id":3,"result":{...}}
```

## Próximos Pasos

Este servidor "Hello World" es la base para:
1. Integración con módulos CyberMAX reales
2. Acceso a bases de datos del ERP
3. Ejecución de procesos de negocio
4. Generación de informes
5. Automatización de tareas administrativas

## Notas de Desarrollo

- **Encoding:** UTF-8 para nuevos archivos
- **Dependencias:** Utiliza unidades del repositorio base sin duplicación
- **RTTI:** Descubrimiento automático de herramientas mediante atributos
- **JSON-RPC 2.0:** Protocolo de comunicación estándar
- **CORS:** Habilitado para permitir conexiones desde Claude Code

---
Última actualización: 2025-09-03
CyberMAX MCP Server v1.0.0