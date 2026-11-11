
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	NumberOfYears = 1;
	EndDate = BegOfDay(CurrentSessionDate())-1;
	StartDate = EndDate - 86400 * 365 * NumberOfYears;
	
	FillingVariant      = Parameters.FillingVariant;
	AllocationShareProcedure = Parameters.AllocationShareProcedure;
	
	If AllocationShareProcedure = 0 Then
		AllocationShareProcedure = 3;
	EndIf; 
	
	If FillingVariant = 1 Then
	
		DataCompositionSchema = Documents.SalesPlansAllocationBaseByCategories.GetTemplate("FillingBySalesStatisticsItemProperty");
	
	ElsIf FillingVariant = 2 Then
	
		DataCompositionSchema = Documents.SalesPlansAllocationBaseByCategories.GetTemplate("FillingBySalesStatisticsVariantProperty");
	
	Else
	
		DataCompositionSchema = Documents.SalesPlansAllocationBaseByCategories.GetTemplate("FillingBySalesStatisticsItemAttributes");
		SearchSubstring = "CatProducts.ItemsGroup";
		ReplaceSubstring = "CatProducts."+Parameters.Attribute;
		DataCompositionSchema.DataSets[0].Query = StrReplace(DataCompositionSchema.DataSets[0].Query, SearchSubstring, ReplaceSubstring);
	
	EndIf; 
	
	
	AddressOfDataCompositionSchema = PutToTempStorage(DataCompositionSchema, UUID);
	
	SettingsSource = New DataCompositionAvailableSettingsSource(AddressOfDataCompositionSchema); 
	SettingsComposer.Initialize(SettingsSource);
	SettingsComposer.LoadSettings(DataCompositionSchema.DefaultSettings);
	
	FormEvents.OnCreateAtServer(ThisForm, StandardProcessing, Cancel);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Fill(Command)
	
	CustomSettingsAddress = PutToTempStorage(SettingsComposer.UserSettings, UUID);
	
	Settings = New Structure;
	Settings.Insert("StartDate",                    StartDate);
	Settings.Insert("EndDate",                 EndDate);
	Settings.Insert("FillingVariant",             FillingVariant);
	Settings.Insert("AllocationShareProcedure",     AllocationShareProcedure);
	Settings.Insert("CustomSettingsAddress", CustomSettingsAddress);
	
	Close(Settings);
	
EndProcedure

&AtClient
Procedure SetDateInterval(Command)
	
	TMCommonUseClient.EditPeriod(
		ThisForm, 
		New Structure("StartDate, EndDate", "StartDate", "EndDate"));
	
EndProcedure

&AtClient
Procedure OpenFilter(Command)
	
	FormParameters = New Structure("SettingsComposer", SettingsComposer);
	OpenForm("Document.SalesPlansAllocationBaseByCategories.Form.FilterForm", FormParameters, ThisForm, UUID);
	
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
