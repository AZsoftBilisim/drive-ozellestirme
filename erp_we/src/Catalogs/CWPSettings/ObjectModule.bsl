#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)
	
	Workplace = EquipmentManagerServerCall.GetClientSWorkplace();
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	Workplace = EquipmentManagerServerCall.GetClientSWorkplace();
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	If ValueIsFilled(Workplace) Then
	
		Query = New Query(
		"SELECT TOP 1
		|	CWPSettings.Ref AS Ref
		|FROM
		|	Catalog.CWPSettings AS CWPSettings
		|WHERE
		|	CWPSettings.Ref <> &Ref
		|	AND CWPSettings.Workplace = &Workplace");
		
		Query.SetParameter("Workplace", Workplace);
		Query.SetParameter("Ref", Ref);
		
		Result = Query.Execute();
		Selection = Result.Select();
		
		If Selection.Next() Then
		
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Đối với chỗ làm việc %1 đã có tùy chỉnh quầy thu ngân %2';
																						|ru = 'Для рабочего места %1 уже существует настройка РМК %2';
																						|en = '%2 Point of sale workplace setting already exists for workplace %1'; fa = '%2 Point of sale workplace setting already exists for workplace %1';
																						|it = 'Per la postazione di lavoro %1 esiste già la configurazione della Postazione di Lavoro del Cassiere %2';
																						|pl = 'Dla miejsca pracy %1 istnieją już ustawienia MPK %2';
																						|tr = '%1Çalışma alanı için halihazırda bir %2RMC ayarı bulunmaktadır '"), Workplace, Selection.Ref);
			
			CommonClientServer.MessageToUser(
				ErrorText,
				ThisObject,
				,
				,
				Cancel);
		
		EndIf;
	
	EndIf;
	
	For Each TSRow In CashRegisters Do
		If Not TSRow.UseWithoutConnectingPeripherals
			And Not ValueIsFilled(TSRow.Peripherals) Then
			
			ErrorText = NStr("vi = 'Chưa điền trường ""Thiết bị""';
							|ru = 'Не заполнено поле ""Оборудование""';
							|en = '""Equipment"" is required'; fa = '""Equipment"" is required';
							|it = 'Il campo ""Attrezzatura"" non è compilato';
							|pl = 'Nie wypełniono pola ""Sprzęt""';
							|tr = '""Ekipman"" alanı doldurulmamış'");
			ErrorAddress = NStr("vi = 'trong dòng %LineNumber% của danh sách ""Quầy thu ngân""';
								|ru = 'в строке %LineNumber% списка ""Кассы ККМ""';
								|en = 'in line %LineNumber% of the ""Cash registers"" list'; fa = 'in line %LineNumber% of the ""Cash registers"" list';
								|it = 'Nella riga %LineNumber% dell''elenco ""Registratori di cassa""';
								|pl = 'w wierszu %LineNumber% listy ""Kasy""';
								|tr = '""yazar kasalar"" listesinin %LineNumber% satırında'");
			ErrorAddress = StrReplace(ErrorAddress, "%LineNumber%", TSRow.LineNumber);
			
			CommonClientServer.MessageToUser(
				ErrorText + " " + ErrorAddress,
				ThisObject,
				CommonClientServer.PathToTabularSection("CashRegisters", TSRow.LineNumber, "Peripherals"),
				,
				Cancel);
			
		EndIf;
	EndDo;
	
	For Each TSRow In POSTerminals Do
		If Not TSRow.UseWithoutConnectingPeripherals
			And Not ValueIsFilled(TSRow.Peripherals) Then
			
			ErrorText = NStr("vi = 'Chưa điền trường ""Thiết bị""';
							|ru = 'Не заполнено поле ""Оборудование""';
							|en = '""Equipment"" is required'; fa = '""Equipment"" is required';
							|it = 'Il campo ""Attrezzatura"" non è compilato';
							|pl = 'Nie wypełniono pola ""Sprzęt""';
							|tr = '""Ekipman"" alanı doldurulmamış'");
			ErrorAddress = NStr("vi = 'trong dòng %LineNumber% của danh sách ""Thu thập thiết bị đầu cuối""';
								|ru = 'в строке %LineNumber% списка ""Эквайринговые терминалы""';
								|en = 'in line %LineNumber% of the ""POS terminals"" list'; fa = 'in line %LineNumber% of the ""POS terminals"" list';
								|it = 'nella riga %LineNumber% dell''elenco ""Terminali di acquisizione""';
								|pl = 'w wierszu %LineNumber% listy ""Terminale acquiringowe""';
								|tr = '""PoS terminalleri"" listesinin %LineNumber% satırında'");
			ErrorAddress = StrReplace(ErrorAddress, "%LineNumber%", TSRow.LineNumber);
			
			CommonClientServer.MessageToUser(
				ErrorText + " " + ErrorAddress,
				ThisObject,
				CommonClientServer.PathToTabularSection("POSTerminals", TSRow.LineNumber, "Peripherals"),
				,
				Cancel);
			
		EndIf;
		
		If Not ValueIsFilled(TSRow.CREPeripherals) Then
			
			ErrorText = NStr("vi = 'Chưa điền trường ""MTT""';
							|ru = 'Не заполнено поле ""ККТ""';
							|en = '""Cash register"" is required'; fa = '""Cash register"" is required';
							|it = '""Cash register"" is required';
							|pl = '""Cash register"" is required';
							|tr = '""Yazar kasa"" alanı doldurulmamış'");
			ErrorAddress = NStr("vi = 'trong dòng %LineNumber% của danh sách ""Thu thập thiết bị đầu cuối""';
								|ru = 'в строке %LineNumber% списка ""Эквайринговые терминалы""';
								|en = 'in line %LineNumber% of the ""POS terminals"" list'; fa = 'in line %LineNumber% of the ""POS terminals"" list';
								|it = 'nella riga %LineNumber% dell''elenco ""Terminali di acquisizione""';
								|pl = 'w wierszu %LineNumber% listy ""Terminale acquiringowe""';
								|tr = '""PoS terminalleri"" listesinin %LineNumber% satırında'");
			ErrorAddress = StrReplace(ErrorAddress, "%LineNumber%", TSRow.LineNumber);
			
			CommonClientServer.MessageToUser(
				ErrorText + " " + ErrorAddress,
				ThisObject,
				CommonClientServer.PathToTabularSection("POSTerminals", TSRow.LineNumber, "CREPeripherals"),
				,
				Cancel);
				
		Else
			CashAccountsFound = CashAccounts.FindRows(New Structure("Peripherals", TSRow.CREPeripherals));	
			CashRegisterCashAccountsFound = CashRegisters.FindRows(New Structure("Peripherals", TSRow.CREPeripherals));	
			If CashRegisterCashAccountsFound.Count() = 0
				And CashAccountsFound.Count() = 0 Then
				
				ErrorText = NStr("ru = 'Настройте кассу ККМ или кассу предприятия, связанную с ККТ эквайрингового терминала';
								|vi = 'Set up a cash register or enterprise cash account related to the POS terminal''s cash register';
								|en = 'Set up a cash register or enterprise cash account related to the POS terminal''s cash register'; fa = 'Set up a cash register or enterprise cash account related to the POS terminal''s cash register';
								|it = 'Set up a cash register or enterprise cash account related to the POS terminal''s cash register';
								|pl = 'Set up a cash register or enterprise cash account related to the POS terminal''s cash register';
								|tr = 'Yazar kasayı veya POS terminali ile bağlantılı olan işletme kasasını yapılandırın.'");
				ErrorAddress = NStr("vi = 'trong dòng %LineNumber% của danh sách ""Thu thập thiết bị đầu cuối""';
									|ru = 'в строке %LineNumber% списка ""Эквайринговые терминалы""';
									|en = 'in line %LineNumber% of the ""POS terminals"" list'; fa = 'in line %LineNumber% of the ""POS terminals"" list';
									|it = 'nella riga %LineNumber% dell''elenco ""Terminali di acquisizione""';
									|pl = 'w wierszu %LineNumber% listy ""Terminale acquiringowe""';
									|tr = '""PoS terminalleri"" listesinin %LineNumber% satırında'");
				ErrorAddress = StrReplace(ErrorAddress, "%LineNumber%", TSRow.LineNumber);
				
				CommonClientServer.MessageToUser(
					ErrorText + " " + ErrorAddress,
					ThisObject,
					CommonClientServer.PathToTabularSection("POSTerminals", TSRow.LineNumber, "CREPeripherals"),
					,
					Cancel);
			EndIf;
		EndIf;
	EndDo;

	For Each TSRow In PaymentSystems Do
		If Not ValueIsFilled(TSRow.ContractForConnectionToPaymentSystem) Then
			
			ErrorText = NStr("vi = 'Chưa điền trường ""Hợp đồng""';
							|ru = 'Не заполнено поле ""Договор""';
							|en = 'The ""Contract"" field is not filled in'; fa = 'The ""Contract"" field is not filled in';
							|it = 'Il campo ""Contratto"" non è compilato';
							|pl = 'Nie wypełniono pola ""Umowa""';
							|tr = '""Sözleşme"" alanı doldurulmamış'");
			ErrorAddress = NStr("vi = 'trong dòng %LineNumber% của danh sách ""Hệ thống thanh toán""';
								|ru = 'в строке %LineNumber% списка ""Платежные системы""';
								|en = 'in line %LineNumber% of the ""Payment systems"" list'; fa = 'in line %LineNumber% of the ""Payment systems"" list';
								|it = 'nella riga %LineNumber% dell''elenco ""Sistemi di pagamento""';
								|pl = 'w wierszu %LineNumber% listy ""Systemy płatnicze""';
								|tr = '""ödeme sistemleri"" listesinin %LineNumber% satırında'");
			ErrorAddress = StrReplace(ErrorAddress, "%LineNumber%", TSRow.LineNumber);
			
			CommonClientServer.MessageToUser(
				ErrorText + " " + ErrorAddress,
				ThisObject,
				CommonClientServer.PathToTabularSection("PaymentSystems", TSRow.LineNumber, "ContractForConnectionToPaymentSystem"),
				,
				Cancel);
			
		EndIf;
	EndDo;
	
	KeyDetailsOfTablePartOfCashRegister = New Array;
	KeyDetailsOfTablePartOfCashRegister.Add("CashRegister");
	KeyDetailsOfTablePartOfCashRegister.Add("UseWithoutConnectingPeripherals");
	KeyDetailsOfTablePartOfCashRegister.Add("Peripherals");
	TMCommonUse.CheckForDuplicatesOfTSStrings(
		ThisObject,
		"CashRegisters",
		KeyDetailsOfTablePartOfCashRegister,
		Cancel,,
		False);
		
	TMCommonUseClientServer.CheckForDuplicatesOfArrayValues(
		ThisObject["CashRegisters"].UnloadColumn("Peripherals"),
		Cancel,
		"CashAccounts CASHREGISTER_",
		"Equipment",
		True);
	
	KeyDetailsOfTablePartOfCheckout = New Array;
	KeyDetailsOfTablePartOfCheckout.Add("CashAccount");
	TMCommonUse.CheckForDuplicatesOfTSStrings(
		ThisObject,
		"CashAccounts",
		KeyDetailsOfTablePartOfCheckout,
		Cancel,,
		False);
		
	KeyDetailsOfTablePartAcquiringTerminals = New Array;
	KeyDetailsOfTablePartAcquiringTerminals.Add("POSTerminal");
	TMCommonUse.CheckForDuplicatesOfTSStrings(
		ThisObject,
		"POSTerminals",
		KeyDetailsOfTablePartAcquiringTerminals,
		Cancel,,
		False);
	
	KeyDetailsOfTablePartAcquiringTerminals = New Array;
	KeyDetailsOfTablePartAcquiringTerminals.Add("ContractForConnectionToPaymentSystem");
	KeyDetailsOfTablePartAcquiringTerminals.Add("Store");
	TMCommonUse.CheckForDuplicatesOfTSStrings(
		ThisObject,
		"PaymentSystems",
		KeyDetailsOfTablePartAcquiringTerminals,
		Cancel,,
		False);

	NotCheckedAttributeArray = New Array;
	NotCheckedAttributeArray.Add("CashRegisters.Peripherals");
	NotCheckedAttributeArray.Add("POSTerminals.Peripherals");
	NotCheckedAttributeArray.Add("POSTerminals.CREPeripherals");
	NotCheckedAttributeArray.Add("PaymentSystems.ContractForConnectionToPaymentSystem");
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

Procedure BeforeWrite(Cancel)
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	Description = String(ThisObject.Workplace);
EndProcedure

#EndRegion

#EndIf