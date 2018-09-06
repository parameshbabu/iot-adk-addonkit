---
external help file: IoTCoreImaging-help.xml
Module Name: IoTCoreImaging
online version:
schema: 2.0.0
---

# Add-IoTSecurityPackages

## SYNOPSIS
Creates the security packages for the specified product/config

## SYNTAX

```
Add-IoTSecurityPackages [-Test] [<CommonParameters>]
```

## DESCRIPTION
Creates the security packages such as DeviceGuard, SecureBoot and BitLocker based on the security settings specified in the product configuration xml file.

## EXAMPLES

### EXAMPLE 1
```
Add-IoTSecurityPackages SampleA Retail
```

## PARAMETERS

### -Test
Switch parameter , if defined includes test certificates in the security packages.```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES
You will need to build an image and create an ffu before you call this function as it requires to scan the FFU image to get the device guard policy.

## RELATED LINKS
