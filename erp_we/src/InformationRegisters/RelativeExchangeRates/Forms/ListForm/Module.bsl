#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	CurrenciesChangeAvailable = AccessRight("Update", Metadata.InformationRegisters.RelativeExchangeRates);
	
	If CurrenciesChangeAvailable Then
		Items.DownloadTheListFromTheTable.Visible = True;
		Items.FormDownloadCBRFCurrencyExchangeRates.Visible = Metadata.DataProcessors.Find("CurrenciesRatesImport") <> Undefined;
		Items.FormDownloadECBExchangeRates.Visible = GetFunctionalOption("UseTheDownloadOfECBExchangeRates");
	Else
		Items.DownloadGroupList.Visible = False;
	EndIf;
	
	If Not GetFunctionalOption("UseMultipleCurrencies") Then
		FilterBaseCurrency = Catalogs.Currencies.GetDefaultCurrency();
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Record_LoadRelativeExchangeRates"
		Or EventName = "Write_CurrenciesRatesImport" Then
		Items.List.Refresh();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure LoadFromTheTable(Command)
	
	OpenForm("InformationRegister.RelativeExchangeRates.Form.LoadForm", , ThisForm);
	
EndProcedure

&AtClient
Procedure FilterBaseCurrencyOnChange(Item)
	SetListFilter(FilterBaseCurrency, "BaseCurrency")
EndProcedure

&AtServer
Procedure SetListFilter(Filter, FieldName)
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		FieldName,
		Filter,
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(Filter));
	
EndProcedure

&AtClient
Procedure DownloadECBExchangeRates(Command)
	FormParameters = New Structure;
	FormParameters.Insert("OpeningFromList", True);
	OpenForm("DataProcessor.DownloadingECBExchangeRates.Form.Form", FormParameters, ThisForm);
EndProcedure

&AtClient
Procedure DownloadCBRFCurrencyExchangeRates(Command)
	
	NameOfOpeningForm = NameOfCBRFCurrencyUploadForm();
	
	If Not IsBlankString(NameOfOpeningForm) Then
		FormParameters = New Structure;
		FormParameters.Insert("OpeningFromList", True);
		OpenForm(NameOfOpeningForm, FormParameters, ThisForm);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Function NameOfCBRFCurrencyUploadForm()
	
	DataProcessorFormName = "";
	
	MetadataProcessing = Metadata.DataProcessors.Find("CurrenciesRatesImport");
	If MetadataProcessing <> Undefined Then
		DataProcessorFormName = MetadataProcessing.DefaultForm.FullName();
	EndIf;
	
	Return DataProcessorFormName;
	
EndFunction

#EndRegion