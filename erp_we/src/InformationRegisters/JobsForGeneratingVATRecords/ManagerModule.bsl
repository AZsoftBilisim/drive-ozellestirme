#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Returns the name of a constant that stores the task number for this register.
// 
// Returns:
//	String - String representation of the name of the constant of the task number of the formation of the movement of the funds.
Function NameOfJobNumberConstant() Export
	
	Return Metadata.Constants.NumberOfJobForGeneratingVATRecords.Name;
	
EndFunction

// Increases the value of the task number in the constant.
//
// Returns:
//	Number - The new task number from the constant Task numberforming Movement Funds.
//
Function IncreaseTaskNumber() Export
	
	Return MonthEndTransactionsServer.IncreaseTaskNumber(NameOfJobNumberConstant());
	
EndFunction

// Returns the value of the task number from a constant.
//
// Returns:
//	Number - The number of the current task from the constant Task numberforming Movement Funds.
//
Function GetTaskNumber() Export
	
	Return MonthEndTransactionsServer.CurTaskNumber(NameOfJobNumberConstant());
	
EndFunction

// This method creates a register entry with the specified parameters.
//
// Parameters:
//	TaskPeriod   - Date - Start of the period for which you need to register a task for calculation
//	TaxInvoice - DocumentRef - document the Registrar who created the movement in the dependent registers
//	Organization - CatalogRef.Companies - organization that needs to be recalculated
//  JobNumber - Number - task number; if omitted, the value from the corresponding constant will be set.
//
Procedure CreateRegisterEntry(TaskPeriod, TaxInvoice, Organization, JobNumber = Undefined) Export
	
	If ExchangePlans.MasterNode() <> Undefined Then
		// In RIB, this register is processed only in the main node.
		Return;
	EndIf;
	
	If JobNumber = Undefined Then
		JobNumber = GetTaskNumber();
	EndIf;
	
	BeginTransaction();
	Try
		
		RecordSet = InformationRegisters.JobsForGeneratingVATRecords.CreateRecordManager();
		RecordSet.Month        = BegOfMonth(TaskPeriod);
		RecordSet.TaxInvoice  = TaxInvoice;
		RecordSet.Organization  = Organization;
		RecordSet.JobNumber = JobNumber;
		RecordSet.Write(True);
		
		CommitTransaction();
	
	Except
		
		RollbackTransaction();
		ErrorText = ErrorProcessing.ErrorMessageForUser(ErrorInfo());
		Raise ErrorText;
	
	EndTry;
	
EndProcedure

// This method creates register entries with the parameters received by the request.
//
// Parameters:
//	Selection - QueryResultSelection - a sample of the data to generate the records.
//  JobNumber - Number - task number; if omitted, the value from the corresponding constant will be set.
//  MinimizeRepetitions - Boolean - Ensures the uniqueness of register entries. 
//                                  True if the transmitted selection contains a non-unique set of fields.
//                                  The default value is True.
//
Procedure CreateRegisterEntriesBasedOnSampleData(Selection, JobNumber = Undefined, MinimizeRepetitions = True) Export
	
	If ExchangePlans.MasterNode() <> Undefined Then
		// In RIB, this register is processed only in the main node.
		Return;
	EndIf;
	
	If Selection.Count() = 0 Then
		Return;
	EndIf;
	
	BeginTransaction();
	
	Try
		
		If JobNumber = Undefined Then
			JobNumber = GetTaskNumber();
		EndIf;
		
		RecordSet = InformationRegisters.JobsForGeneratingVATRecords.CreateRecordSet();
		
		While Selection.Next() Do
			
			If Not ValueIsFilled(Selection.Organization) Then
				Continue;
			EndIf;
			
			Record = RecordSet.Add();
			FillPropertyValues(Record, Selection, "Month, Organization, TaxInvoice");
			Record.JobNumber = JobNumber;
			
		EndDo;
		
		If MinimizeRepetitions Then
			
			TableForConvolution = RecordSet.Unload();
			TableForConvolution.GroupBy("Month, Organization, TaxInvoice");
			RecordSet.Load(TableForConvolution);
			
		EndIf;
		
		RecordSet.Write(ReplacementMode.Merge);
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		ErrorText    = ErrorProcessing.ErrorMessageForUser(ErrorInfo());
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể tạo nhiệm vụ cần lập bản ghi kết chuyển theo thuế GTGT do nguyên nhân: %1';
				|ru = 'Не удалось сформировать задания к формированию движений по НДС по причине: %1';
				|en = 'Cannot generate jobs for generating VAT records. Reason: %1'; fa = 'Cannot generate jobs for generating VAT records. Reason: %1';
				|it = 'Cannot generate jobs for generating VAT records. Reason: %1';
				|pl = 'Cannot generate jobs for generating VAT records. Reason: %1';
				|tr = 'KDV hareketlerini oluşturma görevleri şu nedenden dolayı oluşturulamadı: %1'"),
			ErrorText);
			
		WriteLogEvent(NStr("vi = 'Kế toán thuế GTGT';
							|ru = 'Учет НДС';
							|en = 'VAT accounting'; fa = 'حسابداری مالیات بر ارزش افزوده';
							|it = 'Contabilità IVA';
							|pl = 'Ewidencja VAT';
							|tr = 'KDV muhasebesi'", Common.DefaultLanguageCode()),
			EventLogLevel.Error, , , MessageText);
		
		Raise ErrorText;
		
	EndTry;
	
EndProcedure

// Returns a list of metadata objects that are used for generating register entries.
//
//Returns:
// Array of MetadataObject
Function IncomingMechanismData() Export
	
	IncomingData = VATAccountingERPInternal.IncomingMechanismData();
	
	Return IncomingData;
	
EndFunction

#EndRegion

#EndIf
