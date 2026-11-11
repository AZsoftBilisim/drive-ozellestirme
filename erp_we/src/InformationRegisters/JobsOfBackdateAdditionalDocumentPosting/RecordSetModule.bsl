#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		CheckingAvailabilityOfWritingJobTypesToQueueRegister(ThisObject);
		Return;
	EndIf;
	
	CheckingAvailabilityOfWritingJobTypesToQueueRegister(ThisObject);
	
EndProcedure

Procedure OnWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Procedure CheckingAvailabilityOfWritingJobTypesToQueueRegister(RecordSet)
	
	RegisterMetadata = Metadata();
	RegisterID = Common.MetadataObjectID(RegisterMetadata.FullName());

	ListOfAvailableTypesOfTasks = BackdateJobQueueCached.ListOfAvailableTypesOfTasksForQueueRegister(
		RegisterID);

	For Each Record In ThisObject Do

		If ListOfAvailableTypesOfTasks.Find(Record.JobKind) = Undefined Then

			ExceptionText = NStr(
				"vi = 'Không thể ghi nhận nhiệm vụ có dạng giao dịch ""%1"" trong biểu ghi thuộc hàng đợi ""%2"".';
				|ru = 'Недопустимо регистрировать задание с видом операции ""%1"" в регистре очереди ""%2"".';
				|en = 'Cannot register a job with the ""%1"" operation type in the ""%2"" queue register.'; fa = 'Cannot register a job with the ""%1"" operation type in the ""%2"" queue register.';
				|it = 'Cannot register a job with the ""%1"" operation type in the ""%2"" queue register.';
				|pl = 'Cannot register a job with the ""%1"" operation type in the ""%2"" queue register.';
				|tr = 'İşlem türü ""%1"" olan görevin ""%2"" kuyruk kaydına kaydedilmesine izin verilmez.'");
			Raise StringFunctionsClientServer.SubstituteParametersToString(ExceptionText,
				Record.JobKind, RegisterMetadata.Presentation());

		EndIf;

	EndDo;
	
EndProcedure

#EndRegion

#EndIf