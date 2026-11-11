///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Variables

Var VerificationRequired;
Var DataToWrite;
Var PreparedData1;

#EndRegion

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	// The DataExchange.Load property is not checked since the restrictions
	// imposed by this code block are not supposed to be overridden by setting the property to "True"
	// (in the piece of code that is trying to record an entry into the register).
	//
	// The register must be excluded from the scope of any data exchange if data area separation is enabled.
	// 
	
	If PreparedData1 Then
		Load(DataToWrite);
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel, Replacing)
	
	// The DataExchange.Load property is not checked since the restrictions
	// imposed by this code block are not supposed to be overridden by setting the property to "True"
	// (in the piece of code that is trying to record an entry into the register).
	//
	// The register must be excluded from the scope of any data exchange if data area separation is enabled.
	// 
	
	If VerificationRequired Then
		
		For Each Record In ThisObject Do
			
			VerificationRows = DataToWrite.FindRows(
				New Structure("Id, DataType", Record.Id, Record.DataType));
			
			If VerificationRows.Count() <> 1 Then
				ThrowControlException();
			EndIf;
				
			VerificationRow = VerificationRows.Get(0);
			
			CurrentData = Common.ValueToXMLString(Record.Data.Get());
			VerificationData = Common.ValueToXMLString(VerificationRow.Data.Get());
			
			If CurrentData <> VerificationData Then
				ThrowControlException();
			EndIf;
			
		EndDo;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Procedure PrepareDataToRecord(DataStorage) Export
	
	ReceivingParameters = Undefined;
	If Not AdditionalProperties.Property("ReceivingParameters", ReceivingParameters) Then
		Raise NStr("vi = 'Chưa xác định tham số nhận dữ liệu';
					|ru = 'Не определены параметры получения данных';
					|en = 'The data getting parameters are not defined.'; fa = 'The data getting parameters are not defined.';
					|it = 'Parametri non definiti per la ricezione di dati';
					|pl = 'Parametry zbierania danych nie są zdefiniowane';
					|tr = 'Veri girişi parametreleri belirtilmemiş'");
	EndIf;
	
	DataToWrite = Unload();
	
	For Each String In DataToWrite Do
		
		Data = InformationRegisters.ProgramInterfaceCache.PrepareVersionCacheData(String.DataType, ReceivingParameters);
		DataStorage = New ValueStorage(Data, New Deflation(9));
		String.Data = DataStorage;
	EndDo;
	
	PreparedData1 = True;
	
EndProcedure

Procedure ThrowControlException()
	
	Raise StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Thay đổi không hợp lệ số đo %1 của bản ghi trong biểu ghi thông tin %2
			|bên trong giao tác ghi lại từ phiên làm việc có bật phần chia tách.';
			|ru = 'Недопустимое изменение ресурса %1 записи регистра сведений %2
			|внутри транзакции записи из сеанса с включенным разделением.';
			|en = 'The %1 resource of the %2 information register record cannot be changed
			|inside the record transaction from the session with separation enabled.'; fa = 'The %1 resource of the %2 information register record cannot be changed
			|inside the record transaction from the session with separation enabled.';
			|it = 'Modifica non valido della risorsa%1 di registrazione del registro delle informazioni %2
			| all''interno di una voce di transazione da una sessione con distribuzione inclusa.';
			|pl = 'Nieprawidłowa zmiana zasobu %1 wpisu rejestru informacji %2
			|wewnątrz wpisu z sesji z włączonym podziałem.';
			|tr = 'Bölünme etkin olan oturumdan yazma işlemi içerisinde %2
			| bilgi kayıt defterinin %1 kaynak değişimine izin verilmiyor.'"),
		"Data", "ProgramInterfaceCache");
	
EndProcedure

#EndRegion

#Region Initialize

DataToWrite = New ValueTable();
VerificationRequired = Common.DataSeparationEnabled() And Common.SeparatedDataUsageAvailable();
PreparedData1 = False;

#EndRegion

#Else
Raise NStr("vi = 'Lần gọi không hợp lệ đối tượng trên Client.';
			|ru = 'Недопустимый вызов объекта на клиенте.';
			|en = 'Invalid object call on the client.'; fa = 'Invalid object call on the client.';
			|it = 'Chiamata di oggetto non valida sul client.';
			|pl = 'Niedozwolone wezwanie obiektu na kliencie.';
			|tr = 'İstemcide geçersiz nesne çağrısı.'");
#EndIf