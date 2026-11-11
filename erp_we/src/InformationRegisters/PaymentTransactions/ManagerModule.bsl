#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

// StandardSubsystems.AccessManagement
// See AccessManagementOverridable.OnFillListsWithAccessRestriction.
//
// Parameters:
//  Restriction - Structure:
//    * Text                             - String - restricting access for users.
//                                          If the string is empty, it means that access is allowed.
//    * TextForExternalUsers1      - String - restricting access for external users.
//                                          If the string is empty, it means that access is denied.
//    * ByOwnerWithoutSavingAccessKeys - Undefined - to determine automatically.
//                                        - Boolean - if False, then always write access keys,
//                                          if True, then do not write access keys,
//                                          but use the owner's access keys (it is required
//                                          that the restriction be strictly on the owner object).
//   * ByOwnerWithoutSavingAccessKeysForExternalUsers - Undefined, Boolean - the
//                                          same as for the parameter for the owner of the record of the key access.
//
Procedure OnFillAccessRestriction(Restriction) Export
	
	Manager = "InformationRegister.PaymentTransactions";
	EquipmentManagerServerCallOverridable.OnFillAccessRestriction(Manager, Restriction);
	
EndProcedure
// End StandardSubsystems.AccessManagement

#EndIf

#EndRegion

#Region Internal

Procedure ClearRegisterForPastMonths(ClearDate) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text = 
		"SELECT ALLOWED DISTINCT
		|	PaymentTransactions.YearMonth AS YearMonth
		|FROM
		|	InformationRegister.PaymentTransactions AS PaymentTransactions
		|WHERE
		|	PaymentTransactions.YearMonth < &YearMonthOfCleaning";
	
	YearMonthOfCleaning = Year(ClearDate) * 100 + Month(ClearDate);
	Query.SetParameter("YearMonthOfCleaning", YearMonthOfCleaning);
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	BeginTransaction();
	Try
		Block = New DataLock;
		LockItem = Block.Add("InformationRegister.PaymentTransactions");
		LockItem.DataSource = QueryResult;
		LockItem.UseFromDataSource("YearMonth","YearMonth");
		LockItem.Mode = DataLockMode.Exclusive;
		Block.Lock();
		
		RecordSet = InformationRegisters.PaymentTransactions.CreateRecordSet();
		Selection      = QueryResult.Select();
		While Selection.Next() Do
			RecordSet.Clear();
			RecordSet.Filter.YearMonth.Set(Selection.YearMonth);
			RecordSet.Write(True);
		EndDo;
		CommitTransaction();
	Except
		RollbackTransaction();
		CommonCEL.WriteErrorToEventLog(
			NStr("vi = 'Xóa giao dịch thanh toán';
				|ru = 'Очистка платежных операций';
				|en = 'Clear payment transactions'; fa = 'Clear payment transactions';
				|it = 'Очистка платежных операций';
				|pl = 'Clear payment transactions';
				|tr = 'Ödeme işlemlerinin temizlenmesi'", CommonCEL.DefaultLanguageCode()));
	EndTry
	
EndProcedure

Procedure ClearCurMONTHREGISTER(ClearDate) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	PaymentTransactions.QueryID AS QueryID,
		|	PaymentTransactions.DocumentBasis AS DocumentBasis,
		|	PaymentTransactions.OperationID AS OperationID,
		|	PaymentTransactions.FiscalTransactionID AS FiscalTransactionID,
		|	PaymentTransactions.YearMonth AS YearMonth
		|FROM
		|	InformationRegister.PaymentTransactions AS PaymentTransactions
		|WHERE
		|	PaymentTransactions.YearMonth = &YearMonthOfCleaning
		|	AND PaymentTransactions.RequestDate_ < &ClearDate";
	
	YearMonthOfCleaning = Year(ClearDate) * 100 + Month(ClearDate);
	Query.SetParameter("YearMonthOfCleaning", YearMonthOfCleaning);
	Query.SetParameter("ClearDate",     ClearDate);
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	BeginTransaction();
	Try
		Block = New DataLock;
		LockItem = Block.Add("InformationRegister.PaymentTransactions");
		LockItem.DataSource = QueryResult;
		LockItem.UseFromDataSource("QueryID","QueryID");
		LockItem.Mode = DataLockMode.Exclusive;
		Block.Lock();
		
		RecordSet = InformationRegisters.PaymentTransactions.CreateRecordSet();
		Selection      = QueryResult.Select();
		If CommonCELCached.SubstitutionModeIsAvailable() Then
			While Selection.Next() Do
				FillPropertyValues(RecordSet.Add(), Selection);
			EndDo;
			RecordSet.Write(CommonCELCached.ReplacementModeDeletion());
		Else
			While Selection.Next() Do
				RecordSet.Clear();
				RecordSet.Filter.QueryID.Set(Selection.QueryID);
				RecordSet.Write(True);
			EndDo;
		EndIf;
		CommitTransaction();
	Except
		RollbackTransaction();
		CommonCEL.WriteErrorToEventLog(
			NStr("vi = 'Xóa giao dịch thanh toán';
				|ru = 'Очистка платежных операций';
				|en = 'Clear payment transactions'; fa = 'Clear payment transactions';
				|it = 'Очистка платежных операций';
				|pl = 'Clear payment transactions';
				|tr = 'Ödeme işlemlerinin temizlenmesi'", CommonCEL.DefaultLanguageCode()));
	EndTry
	
EndProcedure

Procedure SetAttributeOfPaymentTransaction(QueryID, Name, Value) Export
	
	SetPrivilegedMode(True);
	
	RequestIdString = String(QueryID);
	
	If ValueIsFilled(RequestIdString) Then
		
		BeginTransaction();
		Try
			Block = New DataLock;
			LockItem = Block.Add("InformationRegister.PaymentTransactions");
			LockItem.SetValue("QueryID", RequestIdString);
			LockItem.Mode = DataLockMode.Exclusive;
			Block.Lock();
			
			RecordSet = InformationRegisters.PaymentTransactions.CreateRecordSet();
			RecordSet.Filter.QueryID.Set(RequestIdString);
			RecordSet.Read();
			If RecordSet.Count()>0 Then
				Record = RecordSet[0];
				Record[Name] = Value;
				RecordSet.Write(True);
			EndIf;
			CommitTransaction();
		Except
			RollbackTransaction();
			MessageText = StrTemplate(
				NStr("vi = 'Lỗi ghi vào nhật ký giao dịch thanh toán: %1';
					|ru = 'Ошибка записи в журнал логирования платежных операций: %1';
					|en = 'An error occurred when logging the payment transactions: %1'; fa = 'An error occurred when logging the payment transactions: %1';
					|it = 'Ошибка записи в журнал логирования платежных операций: %1';
					|pl = 'An error occurred when logging the payment transactions: %1';
					|tr = 'Ödeme işlemlerini günlüğe kaydetme hatası: %1'", CommonCEL.DefaultLanguageCode()), 
				DetailErrorDescription(ErrorInfo()));
			CommonCEL.WriteErrorToEventLog(
				NStr("vi = 'Giao dịch thanh toán';
					|ru = 'Платежные операции';
					|en = 'Payment transactions'; fa = 'تراکنش‌های پرداخت';
					|it = 'Платежные операции';
					|pl = 'Payment transactions';
					|tr = 'Ödeme işlemleri'",  CommonCEL.DefaultLanguageCode()),
					MessageText);
		EndTry;
	EndIf;
	
EndProcedure

#EndRegion

#EndIf