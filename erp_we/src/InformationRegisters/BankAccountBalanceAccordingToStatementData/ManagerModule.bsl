#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(BankAccount.Owner)";

EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#Region Private

// The procedure creates a register entry based on the transmitted data
//
// Parameters:
//    Period - Date - Day of bank statement
//    BankAccount - CatalogRef - link to the reference list item " Bank accounts of organizations"
//    WriteParameters - Structure - Data to write to the register.
//
Procedure CreateEntry(Period, BankAccount, WriteParameters) Export
	
	If BankAccount = Undefined Or BankAccount = Catalogs.CompaniesBankAccounts.EmptyRef()
		Or Not ValueIsFilled(Period) Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	NewRecord = CreateRecordManager();
	NewRecord.Period = Period;
	NewRecord.BankAccount = BankAccount;
	NewRecord.Read();
	FillPropertyValues(NewRecord, WriteParameters);
	NewRecord.Period = Period;
	NewRecord.BankAccount = BankAccount;
	
	Try
		NewRecord.Write();
	Except
		WriteLogEvent(NStr("vi = 'Ghi vào biểu ghi thông tin ""Số dư tại các tài khoản ngân hàng theo dữ liệu sao kê""';
							|ru = 'Запись в регистр сведений ""Остатки на банковских счетах по данным выписок""';
							|en = 'Record in the ""Bank statements imported"" information register'; fa = 'Record in the ""Bank statements imported"" information register';
							|it = 'Scrittura nel registro delle informazioni ""Rimanenze nei conti bancari secondo i dati delle scritture""';
							|pl = 'Wpis do rejestru informacji ""Ostatki na kontach bankowych według info z wyciągów""';
							|tr = '""Ekstre verilerine göre banka hesap bakiyeleri"" bilgi kaydında kayıt'",
			CommonClientServer.DefaultLanguageCode()),
			EventLogLevel.Error,,,
			DetailErrorDescription(ErrorInfo()));
	EndTry;
	SetPrivilegedMode(False);
	
EndProcedure

#EndRegion

#EndIf