
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	InstanceParameters = Parameters.InstanceParameters;
	FillPropertyValues(ThisForm, InstanceParameters);
	Items.OpenForms.Visible = InstanceParameters.FlagOpenForms;
	
	InternationalReportingServer.FillInListOfReportResources(Items.Resource, ResourceCurrencies, InstanceParameters.ChartsOfAccounts);
	ChoiceList = Items.Resource.ChoiceList;
	If IsBlankString(Resource) And ChoiceList.Count() Then
		Resource = Items.Resource.ChoiceList[0].Value;
	EndIf;
	
	MultiplierOfAmounts = Enums.NumberPresentationKinds.Unchanged;
	
	Items.LineOfBusiness.Visible = Catalogs.LinesOfBusiness.AccountingByDirectionsIsUsed();

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure SelectPeriod(Command)

	ChoiceParameters = New Structure("BeginOfPeriod,EndOfPeriod", BeginOfPeriod, EndOfPeriod);
	CallbackDescription = New CallbackDescription("SelectPeriodCompletion", ThisObject);
	OpenForm("CommonForm.SelectAStandardPeriod", ChoiceParameters, Items.SelectPeriod, , , , CallbackDescription);

EndProcedure

&AtClient
Procedure SelectPeriodCompletion(SelectionResult, AddlParameters) Export

	If SelectionResult = Undefined Then
		Return;
	EndIf;
	FillPropertyValues(ThisForm, SelectionResult, "BeginOfPeriod,EndOfPeriod");

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Generate(Command)
	
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	InstanceParameters = InternationalReportingClientServer.NewReportGenerationParameters();
	FillPropertyValues(InstanceParameters, ThisForm);
	InstanceParameters.Resource = Resource;
	InstanceParameters.Currency = ResourceCurrencies[Resource];
	Close(InstanceParameters);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region sh_Shamsi

// Şemsi kutularını ekler / yeniler (Add-ShamsiHandlers.ps1 v2.1)
&AtServer
Procedure sh_ShamsiInit()
	Try
		Common.CommonModule("sh_ShamsiServer").AddShamsiLabels(ThisObject);
	Except
	EndTry;
EndProcedure

// Şemsi kutusu değişince (sh_ShamsiServer.AddShamsiLabels tarafından bağlanır)
&AtClient
Procedure sh_ShamsiOnChange(Item)
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
	Except
		Return;
	EndTry;
	If Not sh_Module.ShamsiFieldOnChange(ThisObject, Item) Then
		Return;
	EndIf;
EndProcedure

// Şemsi kutusundaki takvim butonu: Şemsi takvim penceresini açar
&AtClient
Procedure sh_ShamsiStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	sh_Current = Undefined;
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
		sh_Path = sh_Module.ShamsiFieldMap(ThisObject).Get(Mid(Item.Name, StrLen("sh_ShamsiInput_") + 1));
		If sh_Path <> Undefined Then
			sh_Current = sh_Module.GetDateByPath(ThisObject, sh_Path);
		EndIf;
	Except
	EndTry;
	OpenForm("CommonForm.sh_ShamsiDatePicker", New Structure("Date", sh_Current), Item);
EndProcedure

#EndRegion
