///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	Items.Currencies.ChoiceMode = Parameters.ChoiceMode;

	DateOfCourse = BegOfDay(CurrentSessionDate());
	List.SettingsComposer.Settings.AdditionalProperties.Insert("DateOfCourse", DateOfCourse);

	EditableFields = New Array;
	EditableFields.Add("Rate");
	EditableFields.Add("Repetition");
	EditableFields.Add("RelativeRate");
	
	List.SetRestrictionsForUseInGroup(EditableFields);
	List.SetRestrictionsForUseInOrder(EditableFields);
	List.SetRestrictionsForUseInFilter(EditableFields);

	CurrenciesChangeAvailable = CurrencyRateOperationsInternal.HasRightToChangeExchangeRates();
	CurrenciesImportAvailable = CurrencyRateOperations.IsCurrencyRatesImportAvailable() And CurrenciesChangeAvailable;

	Items.FormPickFromClassifier.Visible = CurrenciesImportAvailable;
	Items.FormImportCurrenciesRates.Visible = CurrenciesImportAvailable;
	If CurrenciesChangeAvailable Then
		TMCommonUseClientServer.SetFormItemProperty(
			Items,
			"FormSelectionFromTheInternationalClassifier",
			"Visible",
			Not CurrenciesImportAvailable);
	EndIf;
	
	If CurrenciesImportAvailable And CurrenciesChangeAvailable Then
		Items.ExchangeRatesImportGroup.Visible = True;
	Else
		Items.ExchangeRatesImportGroup.Visible = False;
	EndIf;
	
	If Not CurrenciesImportAvailable Then
		If CurrenciesChangeAvailable Then
			Items.CreateCurrency.Title = NStr("vi = 'Tạo mới';
												|ru = 'Создать';
												|en = 'Create'; fa = 'ایجاد';
												|it = 'Creare';
												|pl = 'Create';
												|tr = 'Oluştur'");
		EndIf;
		Items.Create.Type = FormGroupType.ButtonGroup;
	EndIf;
	If Not GetFunctionalOption("UseMultipleCurrencies") Then
		Items.Currencies.ChangeRowSet = False;
		Items.FormPickFromClassifier.Visible = False;
		Items.FormImportCurrenciesRates.Visible = False;
	EndIf;
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(SelectionResult, ChoiceSource)

	Items.Currencies.Refresh();
	Items.Currencies.CurrentRow = SelectionResult;

EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_ExchangeRates"
		Or EventName = "Write_CurrenciesRatesImport"
		Or EventName = "Write_RelativeExchangeRates"
		Or EventName = "Record_LoadRelativeExchangeRates"Then
		Items.Currencies.Refresh();
	EndIf;

EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersCurrencies

&AtServerNoContext
Procedure CurrenciesOnGetDataAtServer(TagName, Settings, Rows)

	Var DateOfCourse;

	If Not Settings.AdditionalProperties.Property("DateOfCourse", DateOfCourse) Then
		Return;
	EndIf;

	Query = New Query;
	Query.Text =
	"SELECT
	|	ExchangeRates.Currency AS Currency,
	|	ExchangeRates.BaseCurrency AS BaseCurrency,
	|	ExchangeRates.CourseNumerator AS CourseNumerator,
	|	ExchangeRates.CourseDenominator AS CourseDenominator
	|FROM
	|	InformationRegister.RelativeExchangeRates.SliceLast(&EndOfPeriod, Currency IN (&Currencies)) AS ExchangeRates
	|TOTALS BY
	|	Currency";
	Query.SetParameter("Currencies", Rows.GetKeys());
	Query.SetParameter("EndOfPeriod", DateOfCourse);
	
	QueryResult = Query.Execute();
	
	CurrencySelection_ = QueryResult.Select(QueryResultIteration.ByGroups);
	
	While CurrencySelection_.Next() Do
		
		ListLine = Rows[CurrencySelection_.Currency];
		
		SelectionDetailRecords = CurrencySelection_.Select();
		RelativeRate = "";
		While SelectionDetailRecords.Next() Do
			If SelectionDetailRecords.Currency <> SelectionDetailRecords.BaseCurrency Then
				RelativeRate = ?(IsBlankString(RelativeRate), "", RelativeRate + ", ") + StringFunctionsClientServer.SubstituteParametersToString(
																										NStr("vi = '%1 %2 trong %3 %4';
																											|ru = '%1 %2 за %3 %4';
																											|en = '%1 %2 for %3 %4'; fa = '%1 %2 for %3 %4';
																											|it = '%1 %2 per %3 %4';
																											|pl = '%1 %2 za %3 %4';
																											|tr = '%3%4 tarihli %1%2'"), 
																										SelectionDetailRecords.CourseDenominator,
																										SelectionDetailRecords.Currency,
																										SelectionDetailRecords.CourseNumerator,
																										SelectionDetailRecords.BaseCurrency);
			EndIf;
		EndDo;
		
		ListLine.Data["RelativeRate"] = RelativeRate;
		
	EndDo;

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure PickFromClassifier(Command)

	PickingFormName = "DataProcessor.CurrenciesRatesImport.Form.PickCurrenciesFromClassifier";
	OpenForm(PickingFormName,, ThisObject);

EndProcedure

&AtClient
Procedure ImportCurrenciesRates(Command)

	FormParameters = New Structure("OpeningFromList");

	CurrencyRateOperationsClient.ShowExchangeRatesImport(FormParameters);

EndProcedure

#EndRegion