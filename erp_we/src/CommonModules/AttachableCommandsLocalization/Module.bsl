
// You can define your own types of plug-in commands,
// in addition to those already provided in the standard delivery (printed forms, reports, and fill-in commands).
// See AttachableCommandsOverridable.OnDefineAttachableCommandsKinds
//
Procedure OnDefineAttachableCommandsKinds(AttachableCommandsKinds) Export
	
	
EndProcedure

// Allows you to extend the configuration parameter of the procedure for defining Customizations in the modules of report and 
// processing managers included in the pluggable reports and Processing subsystem, so that reports and processing can 
// report that they provide certain types of commands and interact with subsystems through their 
// program interface.
//
// See AttachableCommandsOverridable.OnDefineAttachableObjectsSettingsComposition
//
Procedure OnDefineAttachableObjectsSettingsComposition(InterfaceSettings4) Export
	
	
EndProcedure

// Called once during the first generation of the list of commands displayed in the form of a specific configuration object.
// The list of added commands should be returned in the Commands parameter.
// The result is cached using the module with repeated use of return values (in the context of form names).
// See AttachableCommandsOverridable.OnDefineCommandsAttachedToObject
//	
Procedure OnDefineCommandsAttachedToObject(FormSettings, Sources, AttachedReportsAndDataProcessors, Commands) Export
	
	
EndProcedure