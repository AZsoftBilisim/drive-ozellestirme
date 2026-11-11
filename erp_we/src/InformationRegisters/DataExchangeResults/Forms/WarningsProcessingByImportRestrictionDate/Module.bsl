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
	
	If Not Parameters.Property("DataForSelectedRows") Then
		
		Raise NStr("vi = 'Không cho phép sử dụng độc lập biểu mẫu.';
					|ru = 'Самостоятельное использование формы не предусмотрено.';
					|en = 'The form cannot be used independently.'; fa = 'The form cannot be used independently.';
					|it = 'Utilizzo autonomo del modulo non previsto.';
					|pl = 'Samodzielne użycie formularza nie jest przewidziane.';
					|tr = 'Form bağımsız kullanılamaz. '", Common.DefaultLanguageCode());
		
	EndIf;
	
	ConditionalFormDesign();
	FillInTheFormTable();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SelectAllCommand(Command)
	
	ChangeTheLineMark(True);
	
EndProcedure

&AtClient
Procedure RemoveSelection(Command)
	
	ChangeTheLineMark(False);
	
EndProcedure

&AtClient
Procedure AcceptVersion(Command)
	
	QueryText = NStr("vi = 'Tiếp nhận phiên bản trong các dòng đã đánh dấu, mặc dù bị cấm kết nhập?';
					|ru = 'Принять версии в отмеченных строках, несмотря на запрет загрузки?';
					|en = 'Accept versions in the selected lines even though import is restricted?'; fa = 'Accept versions in the selected lines even though import is restricted?';
					|it = 'Applicare le versioni nelle righe contrassegnate nonostante il divieto di download?';
					|pl = 'Zastosować wersje w zaznaczonych wierszach, mimo zakazu pobierania?';
					|tr = 'Yükleme yasağına rağmen seçilen satırlardaki versiyonları kabul et?'", CommonClient.DefaultLanguageCode());
	
	CallbackDescription = New CallbackDescription("AcceptVersionCompletion", ThisObject);
	
	ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo, , DialogReturnCode.No);
	
EndProcedure

&AtClient
Procedure AcceptVersionCompletion(Response, AdditionalParameters) Export
	
	If Response <> DialogReturnCode.Yes Then
		
		Return;
		
	EndIf;
	
	RevisionParameters = New Structure;
	RevisionParameters.Insert("NumberOfRevised", 0);
	RevisionParameters.Insert("TotalCount1", 0);
	
	ReviewTheResultsOnTheServer(RevisionParameters);
	
	If RevisionParameters.NumberOfRevised > 0 Then
		
		Notify("CorrectionOfSynchronizationWarningsRevisionOfTheBanDate");
		
	EndIf;
	
	ClearMessages();
	If RevisionParameters.NumberOfRevised <> RevisionParameters.TotalCount1 Then
		
		MessageTemplate = NStr("vi = 'Đánh dấu %1 dòng. Thay đổi %2 đối tượng.';
								|ru = 'Отмечено строк: %1. Изменено объектов: %2.';
								|en = 'Lines selected: %1. Objects changed: %2.'; fa = 'Lines selected: %1. Objects changed: %2.';
								|it = 'Righe contrassegnate: %1. Oggetti modificati: %2.';
								|pl = 'Zaznaczono wierszy: %1. Zmieniono obiektów: %2.';
								|tr = 'Seçilen satırlar: %1. Değiştirilen nesneler: %2.'", CommonClient.DefaultLanguageCode());
		
		ErrorMessage = StringFunctionsClientServer.SubstituteParametersToString(
			MessageTemplate,
			Format(RevisionParameters.TotalCount1, "NZ=; NG=0"),
			Format(RevisionParameters.NumberOfRevised, "NZ=; NG=0"));
		
		ShowMessageBox(Undefined, ErrorMessage);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ShowDifferences(Command)
	
	ShowDifferencesBetweenObjectVersions();
	
EndProcedure

&AtClient
Procedure OpenOtherApplicationVersion(Command)
	
	ShowDifferencesBetweenObjectVersions();
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure ShowDifferencesBetweenObjectVersions()
	
	TheCurrentDataRow = Items.PatchObjectsTable.CurrentData;
	If TheCurrentDataRow = Undefined Then
		
		Return;
		
	EndIf;
	
	VersionsToCompare = New Array;
	VersionsToCompare.Add(TheCurrentDataRow.VersionFromOtherApplication);
	
	OpenVersionComparisonReport(TheCurrentDataRow.ObjectWithIssue, VersionsToCompare);
	
EndProcedure

&AtClient
Procedure ChangeTheLineMark(MarkValue)
	
	For Each SelectedRow In PatchObjectsTable Do
		
		SelectedRow.ProcessString = MarkValue;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure OpenVersionComparisonReport(Ref, VersionsToCompare)
	
	If CommonClient.SubsystemExists("StandardSubsystems.ObjectsVersioning") Then
		
		ModuleObjectsVersioningClient = CommonClient.CommonModule("ObjectsVersioningClient");
		ModuleObjectsVersioningClient.OpenVersionComparisonReport(Ref, VersionsToCompare);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ReviewTheResultsOnTheServer(RevisionParameters)
	
	If Not Common.SubsystemExists("StandardSubsystems.ObjectsVersioning") Then
		
		Return;
		
	EndIf;
	
	ModuleObjectsVersioning = Common.CommonModule("ObjectsVersioning");
	ErrorTextTemplate = NStr("vi = 'Không thể thay đổi phiên bản đối tượng do nguyên nhân:%1%2';
							|ru = 'Не удалось изменить версию объекта по причине:%1%2';
							|en = 'Cannot change the object version due to:%1%2'; fa = 'Cannot change the object version due to:%1%2';
							|it = 'Impossibile modificare la versione dell''oggetto a causa di:%1%2';
							|pl = 'Nie udało się zmienić wersji obiektu z powodu:%1%2';
							|tr = 'Bu nedenle nesne versiyonu değiştirilemedi:%1%2'", Common.DefaultLanguageCode());
	
	For Each SelectedRow In PatchObjectsTable Do
		
		If Not SelectedRow.ProcessString Then
			
			Continue;
			
		EndIf;
		
		RevisionParameters.TotalCount1 = RevisionParameters.TotalCount1 + 1;
		
		Try
			
			ModuleObjectsVersioning.OnStartUsingNewObjectVersion(SelectedRow.ObjectWithIssue, SelectedRow.VersionFromOtherApplication);
			RevisionParameters.NumberOfRevised = RevisionParameters.NumberOfRevised + 1;
			
		Except
			
			ErrorText = ErrorProcessing.BriefErrorDescription(ErrorInfo());
			
			SelectedRow.ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(ErrorTextTemplate, Chars.LF, ErrorText);
			SelectedRow.UnsuccessfulAttempt = True;
			
		EndTry;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure ConditionalFormDesign()
	
	ErrorsInRed = ConditionalAppearance.Items.Add();
	
	CommonClientServer.AddCompositionItem(ErrorsInRed.Filter, "PatchObjectsTable.UnsuccessfulAttempt", DataCompositionComparisonType.Equal, True);
	ErrorsInRed.Appearance.SetParameterValue("TextColor", WebColors.DarkRed);
	
	AppearanceField = ErrorsInRed.Fields.Items.Add();
	AppearanceField.Field = New DataCompositionField("PatchObjectsTableObjectWithIssue");
	AppearanceField = ErrorsInRed.Fields.Items.Add();
	AppearanceField.Field = New DataCompositionField("TableOfObjectsOfCorrectionTheResultOfThe");
	AppearanceField = ErrorsInRed.Fields.Items.Add();
	AppearanceField.Field = New DataCompositionField("PatchObjectsTableUnsuccessfulAttempt");
	
EndProcedure

&AtServer
Procedure FillInTheFormTable()
	
	If TypeOf(Parameters.DataForSelectedRows) <> Type("Array") Then
		
		Return;
		
	EndIf;
	
	For Each RowData In Parameters.DataForSelectedRows Do
		
		NewRow = PatchObjectsTable.Add();
		FillPropertyValues(NewRow, RowData);
		NewRow.ProcessString = True;
		
	EndDo;
	
EndProcedure

#EndRegion
