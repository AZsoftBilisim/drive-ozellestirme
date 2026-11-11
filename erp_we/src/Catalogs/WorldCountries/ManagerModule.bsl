///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InterfaceImplementation

// StandardSubsystems.BatchEditObjects

// Returns the object attributes that are not recommended to be edited
// using a bulk attribute modification data processor.
//
// Returns:
//  Array of String
//
Function AttributesToSkipInBatchProcessing() Export
	
	Result = New Array;
	Result.Add("*");
	Return Result;
	
EndFunction

// End StandardSubsystems.BatchEditObjects

#EndRegion

#EndRegion

#Region EventHandlers

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	If Not StandardProcessing 
		Or Not Parameters.Property("AllowClassifierData")
		Or Not Parameters.AllowClassifierData Then
		Return;
	EndIf;
	
	ContactsManagerInternal.ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
EndProcedure

#EndRegion

#Region Internal

// Determines country data by the country catalog or classifier.
// Use ContactsManager.WorldCountryData.
//
// Parameters:
//    CountryCode    - String
//                 - Number - — a country code by classifier. If not specified, search by code is not executed.
//    Description - String        - a country description. If not specified, search by description is not performed.
//
// Returns:
//    Structure:
//          * Code                - String
//          * Description       - String
//          * DescriptionFull - String
//          * CodeAlpha2          - String
//          * CodeAlpha3          - String
//          * Ref             - CatalogRef.WorldCountries
//    Undefined — the country does not exist.
//
Function WorldCountryData(Val CountryCode = Undefined, Val Description = Undefined) Export
	Return ContactsManager.WorldCountryData(CountryCode, Description);
EndFunction

// Determines country data by the world country classifier.
// Use ContactsManager.WorldCountryClassifierDataByCode.
//
// Parameters:
//    Code - String
//        - Number - — a country code by classifier.
//    CodeType - String - Options: CountryCode (by default), Alpha2, and Alpha3.
//
// Returns:
//    Structure:
//          * Code                - String
//          * Description       - String
//          * DescriptionFull - String
//          * CodeAlpha2          - String
//          * CodeAlpha3          - String
//    Undefined — the country does not exist.
//
Function WorldCountryClassifierDataByCode(Val Code, CodeType = "CountryCode") Export
	Return ContactsManager.WorldCountryClassifierDataByCode(Code, CodeType);
EndFunction

// Determines country data by the classifier.
// Use ContactsManager.WorldCountryClassifierDataByDescription.
//
// Parameters:
//    Description - String - a country description.
//
// Returns:
//    Structure:
//          * Code                - String
//          * Description       - String
//          * DescriptionFull - String
//          * CodeAlpha2          - String
//          * CodeAlpha3          - String
//    Undefined — the country does not exist.
//
Function WorldCountryClassifierDataByDescription(Val Description) Export
	Return ContactsManager.WorldCountryClassifierDataByDescription(Description);
EndFunction

#EndRegion

#Region Private

// See also InfobaseUpdateOverridable.OnSetUpInitialItemsFilling
// 
// Parameters:
//  Settings - See InfobaseUpdateOverridable.OnSetUpInitialItemsFilling.Settings
//
Procedure OnSetUpInitialItemsFilling(Settings) Export
	
	Settings.OnInitialItemFilling = False;
	
EndProcedure

// See also InfobaseUpdateOverridable.OnInitialItemsFilling
// 
// Parameters:
//   LanguagesCodes - See InfobaseUpdateOverridable.OnInitialItemsFilling.LanguagesCodes
//   Items - See InfobaseUpdateOverridable.OnInitialItemsFilling.Items
//   TabularSections - See InfobaseUpdateOverridable.OnInitialItemsFilling.TabularSections
//
Procedure OnInitialItemsFilling(LanguagesCodes, Items, TabularSections) Export
	
	If ContactsManagerInternalCached.AreAddressManagementModulesAvailable() Then
		ModuleAddressManager = Common.CommonModule("AddressManager");
		ModuleAddressManager.OnInitialItemsFilling(LanguagesCodes, Items, TabularSections);
	EndIf;
	
EndProcedure

#Region InfobaseUpdate

// Registers world countries for processing.
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	If Common.SubsystemExists("StandardSubsystems.NationalLanguageSupport") Then
		// Update multilanguage strings if they were modified.
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("UpdateMode", "MultilingualStrings");
		
		InfobaseUpdate.RegisterPredefinedItemsToUpdate(Parameters,
			Metadata.Catalogs.WorldCountries, AdditionalParameters);
	
	EndIf;
	
	CountryList = ContactsManager.CustomEAEUCountries();
	
	NewRow                    = CountryList.Add();
	NewRow.Code                = "203";
	NewRow.Description       = NStr("vi = 'CỘNG HÒA SÉC';
									|ru = 'ЧЕШСКАЯ РЕСПУБЛИКА';
									|en = 'CZECH REPUBLIC'; fa = 'CZECH REPUBLIC';
									|it = 'REPUBBLICA CECA';
									|pl = 'REPUBLIKA CZESKA';
									|tr = 'ÇEK CUMHURİYETİ'");
	NewRow.CodeAlpha2          = "CZ";
	NewRow.CodeAlpha3          = "CZE";
	
	NewRow                    = CountryList.Add();
	NewRow.Code                = "270";
	NewRow.Description       = NStr("vi = 'GAMBIA';
									|ru = 'ГАМБИЯ';
									|en = 'GAMBIA'; fa = 'GAMBIA';
									|it = 'GAMBIA';
									|pl = 'GAMBIA';
									|tr = 'GAMBİYA'");
	NewRow.CodeAlpha2          = "GM";
	NewRow.CodeAlpha3          = "GMB";
	NewRow.DescriptionFull = NStr("vi = 'Cộng hòa Gambia';
									|ru = 'Республика Гамбия';
									|en = 'Republic of the Gambia'; fa = 'Republic of the Gambia';
									|it = 'Repubblica del Gambia';
									|pl = 'Republika Gambia';
									|tr = 'Gambiya Cumhuriyeti'");
	
	NewRow                    = CountryList.Add();
	NewRow.Code                = "807";
	NewRow.Description       = NStr("vi = 'Cộng hòa Macedonia';
									|ru = 'РЕСПУБЛИКА МАКЕДОНИЯ';
									|en = 'REPUBLIC OF MACEDONIA'; fa = 'REPUBLIC OF MACEDONIA';
									|it = 'Repubblica di Macedonia del Nord';
									|pl = 'REPUBLIC OF MACEDONIA';
									|tr = 'Makedonya Cumhuri̇yeti̇'");
	NewRow.CodeAlpha2          = "MK";
	NewRow.CodeAlpha3          = "MKD";
	NewRow.DescriptionFull =  NStr("vi = 'Cộng hòa Macedonia';
									|ru = 'Республика Македония';
									|en = 'Republic of Macedonia'; fa = 'Republic of Macedonia';
									|it = 'Repubblica di Macedonia del Nord';
									|pl = 'Republika Macedonii';
									|tr = 'Makedonya Cumhuri̇yeti̇'");
	
	Query = New Query;
	Query.Text = "SELECT
		|	CountryList.Code AS Code,
		|	CountryList.Description AS Description,
		|	CountryList.CodeAlpha2 AS CodeAlpha2,
		|	CountryList.CodeAlpha3 AS CodeAlpha3,
		|	CountryList.DescriptionFull AS DescriptionFull
		|INTO CountryList
		|FROM
		|	&CountryList AS CountryList
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	WorldCountries.Ref AS Ref
		|FROM
		|	CountryList AS CountryList
		|		INNER JOIN Catalog.WorldCountries AS WorldCountries
		|		ON (WorldCountries.Code = CountryList.Code)
		|			AND (WorldCountries.Description = CountryList.Description)
		|			AND (WorldCountries.CodeAlpha2 = CountryList.CodeAlpha2)
		|			AND (WorldCountries.CodeAlpha3 = CountryList.CodeAlpha3)
		|			AND (WorldCountries.DescriptionFull = CountryList.DescriptionFull)";
	
	Query.SetParameter("CountryList", CountryList);
	QueryResult = Query.Execute().Unload();
	CountriesToProcess = QueryResult.UnloadColumn("Ref");
	
	InfobaseUpdate.MarkForProcessing(Parameters, CountriesToProcess);
	
EndProcedure

Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	WorldCountryForProcessing = InfobaseUpdate.SelectRefsToProcess(Parameters.Queue, "Catalog.WorldCountries");
	SettingsOfUpdate = Undefined;
	If Common.SubsystemExists("StandardSubsystems.NationalLanguageSupport") Then
		ModuleNationalLanguageSupportServer = Common.CommonModule("NationalLanguageSupportServer");
		SettingsOfUpdate = ModuleNationalLanguageSupportServer.SettingsPredefinedDataUpdate(Metadata.Catalogs.WorldCountries);
	EndIf;
	
	ObjectsWithIssuesCount = 0;
	ObjectsProcessed = 0;
	
	While WorldCountryForProcessing.Next() Do
		
		WorldCountryRef = WorldCountryForProcessing.Ref; // CatalogRef.WorldCountries
		RepresentationOfTheReference = String(WorldCountryRef);
		
		Try
			
			CountryCode = Common.ObjectAttributeValue(WorldCountryRef, "Code");
			ClassifierData = ContactsManager.WorldCountryClassifierDataByCode(CountryCode);
			
			If ClassifierData <> Undefined Then
				
				Block = New DataLock();
				LockItem = Block.Add("Catalog.WorldCountries");
				LockItem.SetValue("Ref", WorldCountryRef);
				
				BeginTransaction();
				Try
					
					Block.Lock();
					
					WorldCountry = WorldCountryRef.GetObject();
					FillPropertyValues(WorldCountry, ClassifierData);
					InfobaseUpdate.WriteData(WorldCountry);
					
					CommitTransaction();
					
				Except
					RollbackTransaction();
					Raise;
				EndTry;
				
			Else
				InfobaseUpdate.MarkProcessingCompletion(WorldCountryRef);
			EndIf;
			
			// Update descriptions.
			If Common.SubsystemExists("StandardSubsystems.NationalLanguageSupport") Then
				If SettingsOfUpdate.ObjectAttributesToLocalize.Count() > 0 Then
					ModuleNationalLanguageSupportServer = Common.CommonModule("NationalLanguageSupportServer");
					ModuleNationalLanguageSupportServer.UpdateMultilanguageStringsOfPredefinedItem(WorldCountryRef, SettingsOfUpdate);
				EndIf;
			EndIf;
			
			ObjectsProcessed = ObjectsProcessed + 1;
			
		Except
			// If you cannot process a world country, try again.
			ObjectsWithIssuesCount = ObjectsWithIssuesCount + 1;
			
			InfobaseUpdate.WriteErrorToEventLog(
				WorldCountryRef,
				RepresentationOfTheReference,
				ErrorInfo());
		EndTry;
	EndDo;
	
	Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, "Catalog.WorldCountries");
	
	If ObjectsProcessed = 0 And ObjectsWithIssuesCount <> 0 Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể xử lý một số quốc gia trên thế giới (đã bỏ qua): %1';
				|ru = 'Не удалось обработать некоторые страны мира (пропущены): %1';
				|en = 'Couldn''t process (skipped) some countries: %1'; fa = 'Couldn''t process (skipped) some countries: %1';
				|it = 'Non è stato possibile elaborare alcuni paesi del mondo (saltati): %1';
				|pl = 'Nie udało się przetworzyć niektórych krajów świata (pominięte): %1';
				|tr = 'Dünyanın bazı ülkeleri işlenemedi (atlandı): %1'"), 
			ObjectsWithIssuesCount);
		Raise MessageText;
	Else
		WriteLogEvent(InfobaseUpdate.EventLogEvent(), EventLogLevel.Information,
			Metadata.Catalogs.WorldCountries,,
			StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Quy trình cập nhật đã xử lý phần tiếp theo của các quốc gia trên thế giới:%1';
																			|ru = 'Процедура обновления обработала очередную порцию стран мира: %1';
																			|en = 'The update procedure processed another portion of world countries: %1'; fa = 'The update procedure processed another portion of world countries: %1';
																			|it = 'La procedura di aggiornamento ha elaborato un ulteriore gruppo di paesi del mondo: %1';
																			|pl = 'Procedura aktualizacji przetworzyła kolejną partie państw świata: %1';
																			|tr = 'Güncelleme prosedürü başka bir dünya ülkeleri partisini işledi: %1'"),
				ObjectsProcessed));
	EndIf;
	
EndProcedure

#EndRegion

Function CountriesCodes() Export
	
	QueryText =
	"SELECT
	|	WorldCountries.Ref,
	|	WorldCountries.Code
	|FROM
	|	Catalog.WorldCountries AS WorldCountries";
	
	Query = New Query(QueryText);
	Selection = Query.Execute().Select();
	CountriesCodes = New Map;
	
	While Selection.Next() Do
		CountriesCodes[Selection.Ref] = Selection.Code;
	EndDo;
	
	Return CountriesCodes;
	
EndFunction

#EndRegion

#EndIf

