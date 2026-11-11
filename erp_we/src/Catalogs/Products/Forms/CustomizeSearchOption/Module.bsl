
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	UsePPD              = GetFunctionalOption("UseFullTextSearchWhenSelectingGoods");
	UseTheStandardSearch = Constants.UseStandardSearchWhenSelectingGoods.Get();
	
	If UsePPD Then
		Items.TooltipToAdvancedSearch.CurrentPage = Items.FTSIsUsed;
	Else
		Items.TooltipToAdvancedSearch.CurrentPage = Items.NotFTSIsUsed;
	EndIf;
	
	If UseTheStandardSearch Then
		Items.TooltipToUsingDefaultSettings.CurrentPage = Items.StandardSearch;
	Else
		Items.TooltipToUsingDefaultSettings.CurrentPage = Items.AdvancedSearch;
	EndIf;
	
	If Parameters.GoodsSearchOption = "Default" Then
		UsingDefaultSetting = "Default";
		SearchMode = ?(UseTheStandardSearch, "Standard", "Advanced");
	Else
		UsingDefaultSetting = "Individually";
		SearchMode = ?(Parameters.GoodsSearchOption = "Standard", "Standard", "Advanced");
	EndIf;
	
	If UsingDefaultSetting = "Default" Then
		Items.GroupSearchOption.Enabled = False;	
	Else 
		Items.GroupSearchOption.Enabled = True;
	EndIf;

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

&AtClient
Procedure UsingDefaultSetting1OnChange(Item)
	
	If UsingDefaultSetting = "Default" Then
		Items.GroupSearchOption.Enabled = False;
		SearchMode = ?(UseTheStandardSearch, "Standard", "Advanced");
	Else
		Items.GroupSearchOption.Enabled = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure UsingDefaultSetting2OnChange(Item)
	
	If UsingDefaultSetting = "Default" Then
		Items.GroupSearchOption.Enabled = False;
		SearchMode = ?(UseTheStandardSearch, "Standard", "Advanced");
	Else
		Items.GroupSearchOption.Enabled = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure OK(Command)
	
	ParametersStructure = New Structure;
	
	If UsingDefaultSetting = "Default" Then
		ParametersStructure.Insert("GoodsSearchOption", "Default");
	Else
		ParametersStructure.Insert("GoodsSearchOption", SearchMode);
	EndIf;
	
	ParametersStructure.Insert("UseTheStandardSearch",UseTheStandardSearch);
	
	Close(ParametersStructure);
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	Close(Undefined);
EndProcedure

#EndRegion
#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

