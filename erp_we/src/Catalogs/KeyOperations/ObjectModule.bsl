///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	CheckPriority(Cancel);
	If Cancel Then
		Return;
	EndIf;
	
	MD5Hash = New DataHashing(HashFunction.MD5);
	MD5Hash.Append(Name);
	NameHashTmp = MD5Hash.HashSum;
	NameHash = StrReplace(String(NameHashTmp), " ", "");
EndProcedure

#EndRegion

#Region Private

Procedure CheckPriority(Cancel)
	
	If AdditionalProperties.Property(PerformanceMonitorClientServer.DoNotCheckPriority()) Or Priority = 0 Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.SetParameter("Priority", Priority);
	Query.SetParameter("Ref", Ref);
	Query.Text = 
	"SELECT TOP 1
	|	KeyOperations.Ref AS Ref,
	|	KeyOperations.Description AS Description
	|FROM
	|	Catalog.KeyOperations AS KeyOperations
	|WHERE
	|	KeyOperations.Priority = &Priority
	|	AND KeyOperations.Ref <> &Ref";
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		MessageText = NStr("vi = 'Giao dịch chính với quyền ưu tiên ""%1"" đã tồn tại (%2).';
							|ru = 'Ключевая операция с приоритетом ""%1"" уже существует (%2).';
							|en = 'Key operation priority %1 is not unique (%2 has the same priority).'; fa = 'Key operation priority %1 is not unique (%2 has the same priority).';
							|it = 'Operazione chiave con priorità ""%1"" esiste già (%2).';
							|pl = 'Operacja kluczowa z priorytetem ""%1"" już istnieje (%2).';
							|tr = '""%1"" öncelikli temel işlem zaten var (%2)'");
		MessageText = StrReplace(MessageText, "%1", String(Priority));
		MessageText = StrReplace(MessageText, "%2", Selection.Description);
		WriteLogEvent(NStr("vi = 'Đánh giá hiệu suất';
							|ru = 'Оценка производительности';
							|en = 'Performance monitor'; fa = 'پایشگر عملکرد';
							|it = 'Valutazione delle prestazioni';
							|pl = 'Ocena wydajności';
							|tr = 'Verimlilik değerlendirilmesi'", Common.DefaultLanguageCode()),
			EventLogLevel.Error,, Selection.Ref, MessageText);
		PerformanceMonitorInternal.MessageToUser(MessageText);
		Cancel = True;
	EndIf;
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	If Not PerformanceMonitorServerCallCached.RunPerformanceMeasurements() Then
		IndexTargetTime = CheckedAttributes.Find("ResponseTimeThreshold");
		If IndexTargetTime <> Undefined Then
			CheckedAttributes.Delete(IndexTargetTime);
		EndIf;
	EndIf;
EndProcedure

#EndRegion

#Else
Raise NStr("vi = 'Lần gọi không hợp lệ đối tượng trên Client.';
			|ru = 'Недопустимый вызов объекта на клиенте.';
			|en = 'Invalid object call on the client.'; fa = 'Invalid object call on the client.';
			|it = 'Chiamata di oggetto non valida sul client.';
			|pl = 'Niedozwolone wezwanie obiektu na kliencie.';
			|tr = 'İstemcide geçersiz nesne çağrısı.'");
#EndIf