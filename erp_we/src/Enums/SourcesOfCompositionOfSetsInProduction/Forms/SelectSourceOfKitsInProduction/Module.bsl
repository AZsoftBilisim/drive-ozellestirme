#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SourceOfKitCompositionInProduction = Parameters.SourceOfKitCompositionInProduction;
	
	Items.Specifications.ToolTip = Enums.SourcesOfCompositionOfSetsInProduction.HintOnSourceOfCompositionOfSets(
		Enums.SourcesOfCompositionOfSetsInProduction.Specifications);
	Items.SpecificationsOrConfigurationOptions.ToolTip = Enums.SourcesOfCompositionOfSetsInProduction.HintOnSourceOfCompositionOfSets(
		Enums.SourcesOfCompositionOfSetsInProduction.SpecificationsOrConfigurationOptions);
	Items.KitConfigurations.ToolTip = Enums.SourcesOfCompositionOfSetsInProduction.HintOnSourceOfCompositionOfSets(
		Enums.SourcesOfCompositionOfSetsInProduction.KitConfigurations);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	NotifyChoice(SourceOfKitCompositionInProduction);
EndProcedure

&AtClient
Procedure Cancel(Command)
	Close();
EndProcedure

#EndRegion

