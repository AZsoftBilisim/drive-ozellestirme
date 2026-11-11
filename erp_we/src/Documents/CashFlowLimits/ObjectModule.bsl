#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)
	
	InitializeDocument(FillingData);
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	NotCheckedAttributeArray.Add("Limits.Sum");
	
	CheckLimits(Cancel);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	EmployeeResponsible = Users.CurrentUser();
	
EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure InitializeDocument(FillingData = Undefined)
	
	EmployeeResponsible = Users.CurrentUser();
	
	If TypeOf(FillingData) <> Type("Structure") Or Not FillingData.Property("ActionPeriod") Then
		Period = BegOfMonth(CurrentSessionDate());
	EndIf;
	
EndProcedure

#EndRegion

#Region Other

Procedure CheckLimits(Cancel)
	
	Query = New Query(
	"SELECT
	|	TableLimits.LineNumber,
	|	TableLimits.CashFlowItem
	|INTO TTTableLimits
	|FROM
	|	&TableLimits AS TableLimits
	|WHERE
	|	TableLimits.ThereIsLimit
	|	AND TableLimits.Sum = 0
	|;
	|
	|///////////////////////////////////////////
	|SELECT
	|	TableLimits.LineNumber
	|FROM
	|	TTTableLimits AS TableLimits");
	Query.SetParameter("TableLimits", ThisObject.Limits.Unload());
	Selection = Query.Execute().Select();
	
	DataKey = TMCommonUse.DataKeyForMessageToUser(ThisObject);
	MessageTemplate = NStr("vi = 'Chưa điền cột ""Hạn mức"" tại dòng %1 trong danh sách ""Hạn mức""';
							|ru = 'Не заполнена колонка ""Лимит"" в строке %1 списка ""Лимиты""';
							|en = 'Column ""Limit"" in line %1 of the ""Limits"" list is not filled in'; fa = 'Column ""Limit"" in line %1 of the ""Limits"" list is not filled in';
							|it = 'Non è compilata la colonna ""Limite"" nella riga %1 dell''elenco ""Limiti""';
							|pl = 'Nie wypełniono kolumny ""Лимит"" w wierszu %1 listy ""Лимиты""';
							|tr = '""Limitler"" listesinin%1 satırındaki ""Limit"" sütunu doldurulmadı'");
	
	While Selection.Next() Do
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate, Selection.LineNumber);
		Field = CommonClientServer.PathToTabularSection("Limits", Selection.LineNumber, "Sum");
		CommonClientServer.MessageToUser(MessageText, DataKey, Field, "Object", Cancel);
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf