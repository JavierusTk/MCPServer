# CyberMAX MCP Server

Servidor Model Context Protocol (MCP) para integración con Claude Code.

## Descripción

Este servidor MCP implementado en Delphi proporciona herramientas de ejemplo para la integración con Claude Code, y herramientas avanzadas de captura de mensajes debug del sistema Windows (OutputDebugString). El proyecto incluye:

- **Herramientas básicas**: Funcionalidad "Hello World" para demostrar la integración MCP
- **Herramientas de depuración**: Sistema completo de captura y análisis de mensajes OutputDebugString
- **Arquitectura modular**: Basado en el framework Delphi-MCP-Server con componentes no visuales reutilizables

Construido usando el framework [Delphi-MCP-Server](https://github.com/GDKsoftware/Delphi-MCP-Server).

## Estructura del Proyecto

```
/mnt/w/MCPserver/
├── MCPServerCore.dproj       # Package RTL-only del núcleo
├── MCPServerDesign.dproj     # Package con componentes visuales
├── MCPServerDesign.VCL.dpk   # Package VCL para IDE
├── MCPServerDesign.FMX.dpk   # Package FMX para IDE
├── MCPServer.Engine.pas      # Motor principal del servidor
├── MCPServer.Adapter.pas     # Adaptador para componentes no visuales
├── MCPServer.Config.pas      # Configuración con patrón builder
├── MCPServer.Register.pas    # Registro de componentes en IDE
├── README.md                 # Esta documentación
├── CLAUDE.md                 # Guía para Claude Code
├── settings.ini              # Configuración del servidor
└── Examples/                 # Ejemplos y herramientas
    ├── CyberMaxHelloMCP.dpr/dproj    # Ejemplo básico standalone
    ├── ExampleMCPEngine.dpr/dproj    # Ejemplo con TMCPEngine
    ├── ExampleVCLApp.dpr/dproj       # Aplicación VCL de ejemplo
    └── Tools/                        # Herramientas MCP
        ├── MCPServer.Tool.HelloCyberMax.pas
        ├── MCPServer.Tool.CyberEcho.pas
        ├── MCPServer.Tool.CyberTime.pas
        ├── MCPServer.Tool.StartDebugCapture.pas
        ├── MCPServer.Tool.StopDebugCapture.pas
        ├── MCPServer.Tool.GetDebugMessages.pas
        ├── MCPServer.Tool.GetProcessSummary.pas
        ├── MCPServer.Tool.GetCaptureStatus.pas
        ├── MCPServer.Tool.PauseResumeCapture.pas
        ├── MCPServer.DebugCapture.Core.pas
        └── MCPServer.DebugCapture.Types.pas
```

## Herramientas Disponibles

### Herramientas Básicas

#### 1. hello_cybermax
Devuelve un mensaje de bienvenida del servidor MCP.

**Parámetros:** Ninguno

**Ejemplo de respuesta:**
```
¡Hola desde CyberMAX MCP Server!
Server Version: 1.0.0
MCP Protocol: 2024-11-05
Ready to assist!
```

#### 2. cyber_echo
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

#### 3. cyber_time
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

### Herramientas de Captura de Debug

**Nota:** ¡No se requieren privilegios de administrador! La captura de debug usa objetos de sesión local para capturar mensajes OutputDebugString de aplicaciones de usuario en tu sesión de Windows.

#### 4. start_debug_capture
Inicia una sesión de captura de mensajes OutputDebugString del sistema Windows.

**Parámetros:**
- `sessionname` (string, opcional): Nombre descriptivo de la sesión
- `processfilter` (string, opcional): Filtrar por nombre de proceso
- `messagefilter` (string, opcional): Filtrar mensajes que contengan este texto
- `maxmessages` (integer, opcional): Límite máximo de mensajes (default: 10000)
- `includesystem` (boolean, opcional): Incluir procesos del sistema

**Retorna:** Session ID para usar en otras herramientas

#### 5. stop_debug_capture
Detiene una sesión de captura activa.

**Parámetros:**
- `sessionid` (string, requerido): ID de la sesión a detener

#### 6. get_debug_messages
Recupera los mensajes capturados con filtros opcionales.

**Parámetros:**
- `sessionid` (string, requerido): ID de la sesión
- `limit` (integer, opcional): Máximo de mensajes a retornar (default: 100)
- `offset` (integer, opcional): Offset para paginación
- `sincetimestamp` (string, opcional): Filtrar desde esta fecha/hora
- `processid` (integer, opcional): Filtrar por PID
- `processname` (string, opcional): Filtrar por nombre de proceso
- `messagecontains` (string, opcional): Filtrar mensajes que contengan texto
- `messageregex` (string, opcional): Filtrar con expresión regular

#### 7. get_process_summary
Obtiene estadísticas de procesos que han emitido mensajes.

**Parámetros:**
- `sessionid` (string, requerido): ID de la sesión

#### 8. get_capture_status
Obtiene información del estado de la sesión de captura.

**Parámetros:**
- `sessionid` (string, requerido): ID de la sesión

#### 9. pause_resume_capture
Pausa o reanuda la captura de mensajes.

**Parámetros:**
- `sessionid` (string, requerido): ID de la sesión
- `pause` (boolean, requerido): true para pausar, false para reanudar

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
ServerName=MCP Server
ServerVersion=1.0.0
```

**Nota importante:** El puerto por defecto es 3001 (cambiado desde 3000 para evitar conflictos).

## Compilación

### Prerrequisitos
- RAD Studio 12 (Delphi 29.0)
- Repositorio base Delphi-MCP-Server clonado en `/mnt/w/Delphi-MCP-Server`
- TaurusTLS_RT en los runtime packages

### Compilar los proyectos

#### Opción 1: Ejemplo Standalone (CyberMaxHelloMCP)
```
Compilar Examples/CyberMaxHelloMCP.dproj
```

#### Opción 2: Ejemplo con TMCPEngine
```
Compilar Examples/ExampleMCPEngine.dproj
```

#### Opción 3: Aplicación VCL
```
Compilar Examples/ExampleVCLApp.dproj
```

#### Compilar los packages (para desarrollo de componentes)
```
Compilar MCPServerCore.dproj       # Package RTL-only
Compilar MCPServerDesign.dproj     # Package con componentes visuales
```

**Nota:** El compiler-agent requiere el archivo .dproj

## Ejecución del Servidor

### Ejecutar CyberMaxHelloMCP (ejemplo básico)
```bash
cd /mnt/w/MCPserver/Examples
./CyberMaxHelloMCP.exe
```

### Ejecutar ExampleMCPEngine (con configuración avanzada)
```bash
cd /mnt/w/MCPserver/Examples
./ExampleMCPEngine.exe
```

El servidor mostrará:
```
========================================
 CyberMAX MCP Server - Hello World v1.0
========================================
Server started successfully!

Available tools:
  Basic Tools:
    - hello_cybermax        : Get greeting and CyberMAX info
    - cyber_echo           : Echo back your message
    - cyber_time           : Get current system time

  Debug Capture Tools:
    - start_debug_capture  : Start capturing OutputDebugString
    - stop_debug_capture   : Stop capture session
    - get_debug_messages   : Retrieve captured messages
    - get_process_summary  : Get process statistics
    - get_capture_status   : Get session information
    - pause_resume_capture : Pause/resume capture

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

### Componentes Principales

#### TMCPEngine
Componente no visual principal que encapsula toda la funcionalidad del servidor MCP:
- Gestión automática del ciclo de vida del servidor
- Configuración mediante propiedades publicadas
- Eventos para logging y control
- Auto-registro de herramientas
- Soporte para CORS

#### TMCPAdapter
Componente adaptador que permite usar TMCPEngine en aplicaciones VCL/FMX:
- Propiedades publicadas para configuración en tiempo de diseño
- Eventos visibles en el Object Inspector
- Integración con el IDE de Delphi

#### TMCPConfig
Clase de configuración con patrón builder:
```pascal
Config := TMCPConfig.Create
  .WithPort(3001)
  .WithHost('localhost')
  .WithServerName('MCP Server')
  .WithCORS(True);
```

### Patrón de Herramientas

Cada herramienta implementa:

1. **Clase de Parámetros** con atributos RTTI para generación de esquema
2. **Clase de Herramienta** extendiendo `TMCPToolBase<TParams>`
3. **Registro automático** en la sección initialization

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

## Casos de Uso

### Depuración de Aplicaciones Windows
Las herramientas de captura de debug permiten:
- Monitorear mensajes OutputDebugString en tiempo real
- Filtrar por proceso o contenido de mensaje
- Analizar comportamiento de aplicaciones sin modificar código
- Depurar problemas intermitentes en producción

## Desarrollo de Nuevas Herramientas

Para agregar una nueva herramienta:

1. Crear clase de parámetros con atributos de esquema
2. Implementar la herramienta extendiendo `TMCPToolBase<TParams>`
3. Registrar en la sección initialization
4. La herramienta se descubre automáticamente mediante RTTI

Ejemplo mínimo:
```pascal
type
  TMyParams = class
    [SchemaDescription('Descripción del parámetro')]
    property MyParam: string read FMyParam write FMyParam;
  end;

  TMyTool = class(TMCPToolBase<TMyParams>)
  protected
    function ExecuteWithParams(const Params: TMyParams): string; override;
  public
    constructor Create; override;
  end;

initialization
  TMCPRegistry.RegisterTool('my_tool', function: IMCPTool
    begin Result := TMyTool.Create; end);
```

## Notas Técnicas

- **Plataforma:** Windows (requiere APIs de Windows para captura de debug)
- **Privilegios:** No se necesitan derechos de administrador para captura de debug - usa objetos de sesión local
- **Detección de Conflictos:** Detecta y reporta automáticamente si DebugView u otros depuradores están ejecutándose
- **Encoding:** UTF-8 para nuevos archivos
- **Protocolo:** MCP sobre JSON-RPC 2.0
- **RTTI:** Descubrimiento automático de herramientas
- **Thread-safe:** Captura de debug en thread separado con sincronización completa
- **CORS:** Configurable para desarrollo

---
Última actualización: 2025-09-17
MCP Server v2.0.0