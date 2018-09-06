---
external help file: IoTCoreImaging-help.xml
Module Name: IoTCoreImaging
online version:
schema: 2.0.0
---

# Add-IoTSecureBoot

## SYNOPSIS
Generates the secure boot package contents based on the workspace specifications. If Test is specified, then it includes test certificates from the specification.

## SYNTAX

```
Add-IoTSecureBoot [[-Test] <Boolean>]
```

## DESCRIPTION
Generates the secure boot package contents based on the workspace specifications. If Test is specified, then it includes test certificates from the specification.

## EXAMPLES

### Example 1
```powershell
PS C:\> Add-IoTSecureBoot
```

Generates the secure boot package contents based on the workspace specifications. 

## PARAMETERS

### -Test
Boolean to specify whether to include test certificates.

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

### None


## OUTPUTS

### System.Object

## NOTES

## RELATED LINKS