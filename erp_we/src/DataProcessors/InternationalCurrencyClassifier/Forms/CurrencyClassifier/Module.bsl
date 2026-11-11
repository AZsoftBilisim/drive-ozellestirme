///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2020, 1C-Soft LLC
// All rights reserved. This program and accompanying materials are provided 
// in accordance with the terms of the Attribution 4.0 International (CC BY 4.0) license
// The license text is available at the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.MultipleChoiceIsProhibited Then
		Items.ListOfCurrencies.MultipleChoice = False;
	EndIf;
	
	CloseOnChoice = False;
	FillInCurrencyTable();
	
	If Common.IsMobileClient() Then
		Items.Downloading.TitleLocation = FormItemTitleLocation.Auto;
		Items.CountriesAndTerritories.Title = NStr("vi = 'Quốc gia';
													|ru = 'Страны';
													|en = 'Countries'; fa = 'کشورها';
													|it = 'Paesi';
													|pl = 'Countries';
													|tr = 'Ülkeler'");
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersListOfCurrencies

&AtClient
Procedure ListOfCurrenciesSelection(Item, RowSelected, Field, StandardProcessing)
	
	ProcessSelectionInListOfCurrencies(StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SelectExecute()
	
	ProcessSelectionInListOfCurrencies();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Function TextInBoolean(StringValue)
	
	If IsBlankString(StringValue) Or StringValue = Undefined Then
		Return False;
	EndIf;
	
	Return TrimAll(StringValue) = "true";
	
EndFunction

&AtServer
Procedure FillInCurrencyTable()

	SpreadsheetDocument = DataProcessors.InternationalCurrencyClassifier.GetTemplate("InternationalCurrencyClassifier");
	
	For CntRow = 2 To SpreadsheetDocument.TableHeight Do

		NewRow = Currencies.Add();
		NewRow.DigitalCurrencyCode = SpreadsheetDocument.Area(CntRow, 1).Text;
		NewRow.TheCurrencyCodeIsAlphabetic = SpreadsheetDocument.Area(CntRow, 2).Text;
		NewRow.Description = SpreadsheetDocument.Area(CntRow, 3).Text;
		NewRow.CountriesAndTerritories = SpreadsheetDocument.Area(CntRow, 4).Text;
		NewRow.AmountInWordsParameters = SpreadsheetDocument.Area(CntRow, 5).Text;
		NewRow.Downloading = TextInBoolean(SpreadsheetDocument.Area(CntRow, 6).Text);
		
	EndDo;
	
EndProcedure

&AtServer
Function SaveSelectedLines(Val RowsSelected, ThereAreCourses)
	
	ThereAreCourses = False;
	CurrentRef = Undefined;
	
	For Each LineNumber In RowsSelected Do
		CurrentData = Currencies[LineNumber];
		
		StringInDatabase = Catalogs.Currencies.FindByCode(CurrentData.DigitalCurrencyCode);
		If ValueIsFilled(StringInDatabase) Then
			If LineNumber = Items.ListOfCurrencies.CurrentRow Or CurrentRef = Undefined Then
				CurrentRef = StringInDatabase;
			EndIf;
			Continue;
		EndIf;
		
		BeginTransaction();
		Try
			
			NewRow = Catalogs.Currencies.CreateItem();
			NewRow.Code                       = CurrentData.DigitalCurrencyCode;
			NewRow.Description              = CurrentData.TheCurrencyCodeIsAlphabetic;
			NewRow.DescriptionFull        = CurrentData.Description;
			If CurrentData.Downloading Then
				NewRow.RateSource = Enums.RateSources.DownloadFromInternet;
			Else
				NewRow.RateSource = Enums.RateSources.ManualInput;
			EndIf;
			NewRow.AmountInWordsParameters = CurrentData.AmountInWordsParameters;
			NewRow.Write();
			
			ProcessingOfExchangeRatesTM.CheckCorrectnessOfRelativeRateOn01_01_1980(NewRow.Ref);
			
			If LineNumber = Items.ListOfCurrencies.CurrentRow Or CurrentRef = Undefined Then
				CurrentRef = NewRow.Ref;
			EndIf;
			
			If CurrentData.Downloading Then 
				ThereAreCourses = True;
			EndIf;
			
			CommitTransaction();
		Except
			RollbackTransaction();
			Raise;
		EndTry;
		
	EndDo;
	
	Return CurrentRef;

EndFunction

&AtClient
Procedure ProcessSelectionInListOfCurrencies(StandardProcessing = Undefined)
	Var ThereAreCourses;
	
	// Adding a directory element and displaying the result to the user.
	StandardProcessing = False;
	
	CurrentRef = SaveSelectedLines(Items.ListOfCurrencies.SelectedRows, ThereAreCourses);
	
	NotifyChoice(CurrentRef);
	Notify("Write_Currencies", CurrentRef);
	
	Close();
	
EndProcedure

#EndRegion
