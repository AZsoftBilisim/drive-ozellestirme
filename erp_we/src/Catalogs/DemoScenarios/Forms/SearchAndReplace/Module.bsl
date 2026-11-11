
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	DemoScenario = Parameters.DemoScenario;
	FieldWithAnErrorBackground          = StyleColors.FieldWithAnErrorBackground;
	FieldBackground                  = StyleColors.FieldBackColor;
	
	SelectionListsClientServer.Load("HistoryThatWeAreChangingDemoScenarios", Items.WhatWeAreChanging.ChoiceList);
	SelectionListsClientServer.Load("HistoryWhatAreWeChangingDemoScriptsTo", Items.WhatAreWeChangingTo.ChoiceList);
	
	If Parameters.Property("SearchParametersWhenOpening") Then
		
		FillPropertyValues(ThisObject, Parameters.SearchParametersWhenOpening);
		PerformSearchWhenOpening = True;
		
	EndIf;

EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If PerformSearchWhenOpening Then
		
		PerformSearchForAllOccurrences();
		
	Else
		
		AvailabilityControl();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeLoadDataFromSettingsAtServer(Settings)
	
	If PerformSearchWhenOpening Then
		
		Settings.Delete("WhatAreWeChangingTo");
		Settings.Delete("WhatWeAreChanging");
		Settings.Delete("CaseSensitive");
		Settings.Delete("SearchForWholeWord");
		
	EndIf;

EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "DemoScenarios_ChangingParametersOfSearchAndReplaceForm" Then 
		
		If Parameter.DemoScenario <> DemoScenario Then
			Return;
		EndIf;
		
		AvailabilityControl(Parameter);
		
	EndIf;

EndProcedure

#EndRegion 

#Region FormHeaderItemsEventHandlers 

&AtClient
Procedure WhatWeAreChangingOnChange(Item)
	
	AvailabilityControl();
	
EndProcedure

&AtClient
Procedure WhatAreWeChangingToOnChange(Item)
	
	AvailabilityControl();
	
EndProcedure

&AtClient
Procedure WhatWeAreChangingAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	SelectionListsClientServer.AutoComplete(Item, Text, ChoiceData, Waiting, StandardProcessing);
	
EndProcedure

&AtClient
Procedure WhatAreWeChangingToAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	SelectionListsClientServer.AutoComplete(Item, Text, ChoiceData, Waiting, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure FindNext(Command)
	
	FormNotificationParameters = FormNotificationParameters();
	FormNotificationParameters.Operation = "FindNext";
	
	Notify("DemoScenarios_SearchAndReplace", FormNotificationParameters, FormOwner);
	
EndProcedure 

&AtClient
Procedure Replace(Command)
	
	FormNotificationParameters = FormNotificationParameters();
	FormNotificationParameters.Operation = "ReplaceCur";
	
	Notify("DemoScenarios_SearchAndReplace", FormNotificationParameters, FormOwner);

EndProcedure

&AtClient
Procedure ReplaceAll(Command)
	
	FormNotificationParameters = FormNotificationParameters();
	FormNotificationParameters.Operation = "ReplaceAllOccurrences";
	
	Notify("DemoScenarios_SearchAndReplace", FormNotificationParameters, FormOwner);

EndProcedure

&AtClient
Procedure FindPrevious(Command)
	
	FormNotificationParameters = FormNotificationParameters();
	FormNotificationParameters.Operation = "FindPrevious";
	
	Notify("DemoScenarios_SearchAndReplace", FormNotificationParameters, FormOwner);
	
EndProcedure

&AtClient
Procedure FindAllOccurrences(Command)
	
	Items.WhatWeAreChanging.BackColor = FieldBackground;
	
	PerformSearchForAllOccurrences();
	
	SelectionListsClientServer.UpdateSelectionList(Items.WhatWeAreChanging.ChoiceList, WhatWeAreChanging, 1000);
	SelectionListsClientServer.UpdateSelectionList(Items.WhatAreWeChangingTo.ChoiceList, WhatAreWeChangingTo, 1000);
	
	SelectionListsClientServer.Save("HistoryThatWeAreChangingDemoScenarios", Items.WhatWeAreChanging.ChoiceList);
	SelectionListsClientServer.Save("HistoryWhatAreWeChangingDemoScriptsTo", Items.WhatAreWeChangingTo.ChoiceList);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure PerformSearchForAllOccurrences()
	
	FormNotificationParameters = FormNotificationParameters();
	FormNotificationParameters.Operation = "FindAllOccurrences";
	
	Notify("DemoScenarios_SearchAndReplace", FormNotificationParameters, FormOwner);
	
EndProcedure

&AtClient
Function FormNotificationParameters()

	NotificationParameters = New Structure;
	NotificationParameters.Insert("WhatWeAreChanging",                WhatWeAreChanging);
	NotificationParameters.Insert("WhatAreWeChangingTo",              WhatAreWeChangingTo);
	NotificationParameters.Insert("CaseSensitive",         CaseSensitive);
	NotificationParameters.Insert("SearchForWholeWord",       SearchForWholeWord);
	NotificationParameters.Insert("DemoScenario", DemoScenario);
	NotificationParameters.Insert("HowToSearchInHyperlinks",   "Ignore");
	NotificationParameters.Insert("Operation",                 "");
	
	Return NotificationParameters;
	
EndFunction

&AtClient
Procedure AvailabilityControl(NotificationParameters = Undefined)
	
	ThereIsSomethingToLookFor = StrLen(WhatWeAreChanging) > 1;
	
	Items.FormFind.Enabled = ThereIsSomethingToLookFor;
	
	If NotificationParameters = Undefined Then
		
		Items.FormFindNext.Enabled  = False;
		Items.FormFindPrevious.Enabled = False;
		Items.FormReplace.Enabled        = False;
		Items.FormReplaceAll.Enabled     = False;
		Items.WhatWeAreChanging.BackColor               = FieldBackground;
		
	Else
		
		Items.FormFindNext.Enabled  = ThereIsSomethingToLookFor And NotificationParameters.ThereIsFollowingResult;
		Items.FormFindPrevious.Enabled = ThereIsSomethingToLookFor And NotificationParameters.ThereIsPreviousResult;
		Items.FormReplace.Enabled        = ThereIsSomethingToLookFor And NotificationParameters.ThereIsCurCurrentSearchResult;
		Items.FormReplaceAll.Enabled     = ThereIsSomethingToLookFor And NotificationParameters.ThereAreSearchResults; 
		Items.WhatWeAreChanging.BackColor               = ?(NotificationParameters.ThereAreSearchResults, FieldBackground, FieldWithAnErrorBackground);
	
	EndIf;

EndProcedure

#EndRegion
