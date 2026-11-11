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
	
	ObjectReference = Parameters.Ref;
	
	CommonTemplate = InformationRegisters.ObjectsVersions.GetTemplate("StandardObjectPresentationTemplate");
	
	LightGrayColor = StyleColors.InaccessibleCellTextColor;
	VioletRedColor = StyleColors.DeletedAttributeTitleBackground;
	
	If TypeOf(Parameters.VersionsToCompare) = Type("Array") Then
		VersionsToCompare = New ValueList;
		For Each VersionNumber In Parameters.VersionsToCompare Do
			VersionsToCompare.Add(VersionNumber, VersionNumber);
		EndDo;
	ElsIf TypeOf(Parameters.VersionsToCompare) = Type("ValueList") Then
		VersionsToCompare = Parameters.VersionsToCompare;
	Else // Using the passed object version.
		SerializedObject = GetFromTempStorage(Parameters.SerializedObjectAddress);
		If Parameters.ByVersion Then // Using single-version report.
			ReportTable = ObjectsVersioning.ReportOnObjectVersion(ObjectReference, SerializedObject);
		EndIf;
		Return;
	EndIf;
		
	VersionsToCompare.SortByValue();
	If VersionsToCompare.Count() > 1 Then
		VersionNumberString = "";
		For Each Version In VersionsToCompare Do
			VersionNumberString = VersionNumberString + String(Version.Presentation) + ", ";
			ObjectVersion = ObjectsVersioning.ObjectVersionInfo(ObjectReference, Version.Value).ObjectVersion;
			If TypeOf(ObjectVersion) = Type("Structure") And ObjectVersion.Property("SpreadsheetDocuments") Then
				SpreadsheetDocuments.Add(ObjectVersion.SpreadsheetDocuments);
			EndIf;
		EndDo;
		
		VersionNumberString = Left(VersionNumberString, StrLen(VersionNumberString) - 2);
		
		Title = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'So sánh các phiên bản ""%1"" (# %2)';
																				|ru = 'Сравнение версий ""%1"" (№№ %2)';
																				|en = 'Comparing versions of ""%1"" (#%2)'; fa = 'Comparing versions of ""%1"" (#%2)';
																				|it = 'Confronto versioni ""%1"" (№№%2)';
																				|pl = 'Porównanie wersji ""%1"" (NrNr %2)';
																				|tr = '""%1"" (no.%2) sürümünü karşılaştır'"),
			Common.SubjectString(ObjectReference), VersionNumberString);
	Else
		Title = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Phiên bản của đối tượng ""%1"" #%2';
																				|ru = 'Версия объекта ""%1"" №%2';
																				|en = 'Object %1 version #%2'; fa = 'Object %1 version #%2';
																				|it = 'Versione oggetto ""%1"" №%2';
																				|pl = 'Wersja obiektu ""%1"" Nr%2';
																				|tr = '""%1"" nesnesinin no.%2 revizyonu'"),
			ObjectReference, String(VersionsToCompare[0].Presentation));
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	Generate();
EndProcedure


#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ReportTableSelection(Item, Area, StandardProcessing)
	
	Details = Area.Details;
	
	If TypeOf(Details) = Type("Structure") Then
		
		StandardProcessing = False;
		
		If Details.Property("Compare") Then
			OpenSpreadsheetDocumentsComparisonForm(Details.Compare, Details.Version0, Details.Version1);
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure Generate()
	If VersionsToCompare.Count() = 1 Then
		GenerateVersionReport();
	Else
		CommonClientServer.SetSpreadsheetDocumentFieldState(Items.ReportTable, "ReportGeneration");
		AttachIdleHandler("StartGenerateVersionsReport", 0.1, True);
	EndIf;
EndProcedure

&AtClient
Procedure StartGenerateVersionsReport()
	TimeConsumingOperation = GenerateVersionsReport();
	
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	IdleParameters.OutputIdleWindow = False;
	
	CallbackDescription = New CallbackDescription("OnCompleteGenerateReport", ThisObject);
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackDescription, IdleParameters);
EndProcedure

&AtServer
Function GenerateVersionsReport()
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(New UUID());
	ReportParameters = New Structure;
	ReportParameters.Insert("ObjectReference", ObjectReference);
	ReportParameters.Insert("VersionsList", VersionsToCompare);
	Return TimeConsumingOperations.ExecuteInBackground("InformationRegisters.ObjectsVersions.GenerateReportOnChanges", 
		ReportParameters, ExecutionParameters);
EndFunction

// Parameters:
//  Result - See TimeConsumingOperationsClient.NewResultLongOperation
//  AdditionalParameters - Undefined
//
&AtClient
Procedure OnCompleteGenerateReport(Result, AdditionalParameters) Export
	If Result = Undefined Then
		Return;
	EndIf;
	CommonClientServer.SetSpreadsheetDocumentFieldState(Items.ReportTable, "DontUse");
	If Result.Status = "Completed2" Then
		ReportTable = GetFromTempStorage(Result.ResultAddress);
	Else
		StandardSubsystemsClient.OutputErrorInfo(Result.ErrorInfo);
	EndIf;
EndProcedure

&AtServer
Procedure GenerateVersionReport()
	ReportTable = ObjectsVersioning.ReportOnObjectVersion(ObjectReference, VersionsToCompare[0].Value, VersionsToCompare[0].Presentation);
EndProcedure

&AtClient
Procedure OpenSpreadsheetDocumentsComparisonForm(SpreadsheetDocumentName, Version0, Version1)
	
	TitleLayout = NStr("vi = 'Phiên bản số %1';
						|ru = 'Версия №%1';
						|en = 'Version #%1'; fa = 'Version #%1';
						|it = 'Versione №%1';
						|pl = 'Wersja Nr%1';
						|tr = 'Sürüm No%1'");
	VersionNumber0 = Format(VersionsToCompare[Version0], "NG=0");
	VersionNumber1 = Format(VersionsToCompare[Version1], "NG=0");
	
	FormOpenParameters = StandardSubsystemsClient.SpreadsheetComparisonParameters();
	FormOpenParameters.SpreadsheetDocumentsAddress = SpreadsheetDocumentsAddress(SpreadsheetDocumentName, Version1, 
		Version0);
	FormOpenParameters.TitleLeft = StringFunctionsClientServer.SubstituteParametersToString(TitleLayout, 
		VersionNumber1);
	FormOpenParameters.TitleRight = StringFunctionsClientServer.SubstituteParametersToString(TitleLayout, 
		VersionNumber0);
	StandardSubsystemsClient.ShowSpreadsheetComparison(Undefined, Undefined, 
		FormOpenParameters);
	
EndProcedure

&AtServer
Function SpreadsheetDocumentsAddress(SpreadsheetDocumentName, Left_1, Right) 
	
	SpreadsheetDocumentLeft = SpreadsheetDocuments[Left_1].Value[SpreadsheetDocumentName].Data;
	SpreadsheetDocumentRight = SpreadsheetDocuments[Right].Value[SpreadsheetDocumentName].Data;
	
	ComparableDocuments = New Structure("Left_1, Right", SpreadsheetDocumentLeft, SpreadsheetDocumentRight);
	Return PutToTempStorage(ComparableDocuments, UUID);
	
EndFunction

#EndRegion


