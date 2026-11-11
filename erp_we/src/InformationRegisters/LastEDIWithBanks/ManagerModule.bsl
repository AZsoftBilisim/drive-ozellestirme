#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

// The procedure creates a register entry based on the transmitted data
//
// Parameters:
//    BankAccount - CatalogRef - link to the reference list item " Bank accounts of organizations"
//    WriteParameters - Structure - Data to write to the register.
//
Procedure CreateEntry(BankAccount, WriteParameters) Export
	
	If BankAccount = Undefined Or BankAccount = Catalogs.CompaniesBankAccounts.EmptyRef() Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	NewRecord = CreateRecordManager();
	NewRecord.BankAccount = BankAccount;
	NewRecord.Read();
	FillPropertyValues(NewRecord, WriteParameters);
	NewRecord.BankAccount = BankAccount;
	
	Try
		NewRecord.Write();
	Except
		WriteLogEvent(NStr("vi = 'Ghi vào biểu ghi thông tin ""Trao đổi lần cuối với ngân hàng""';
							|ru = 'Запись в регистр сведений ""Последний обмен с банками""';
							|en = 'Write to the ""Last bank feeds"" information register'; fa = 'Write to the ""Last bank feeds"" information register';
							|it = 'Scrittura nel registro delle informazioni ""Ultimo scambio con le banche""';
							|pl = 'Wpis do rejestru informacyjnego ""Ostatnia wymiana z bankami""';
							|tr = '""Bankalarla son değişim"" bilgi kaydına kayıt'",
			CommonClientServer.DefaultLanguageCode()),
			EventLogLevel.Error,,,
			DetailErrorDescription(ErrorInfo()));
	EndTry;
	SetPrivilegedMode(False);
	
EndProcedure

#EndRegion

#EndIf