#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)
	
	If TypeOf(FillingData) = Type("Structure")
		And FillingData.Property("PostingGenerationSetting") Then
		ChartOfAccounts = Common.ObjectAttributeValue(FillingData.PostingGenerationSetting, "Owner");
		FillingData.Insert("ChartOfAccounts", ChartOfAccounts);
	EndIf;
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	AttributesNotToCheck = New Array;
	AttributesNotToCheck.Add("GLAccountDr");
	AttributesNotToCheck.Add("GLAccountCr");
	
	RecordStructure = New Structure;
	For Each Dimension In Metadata().Dimensions Do
		RecordStructure.Insert(Dimension.Name);
	EndDo;
	
	For Each Record In ThisObject Do
		
		FillPropertyValues(RecordStructure, Record);
		RecordKey = InformationRegisters.SettingsForReflectingCorrespondenceInFinancialAccounting.CreateRecordKey(RecordStructure);
		
		TransactionSettings = Catalogs.FinancialAccountingPostingGenerationSetting.TransactionGenerationSettings(
			Record.PostingGenerationSetting);
		
		AccountingSettings = FinancialAccountingByFinancialRegisterData.AccountingSettingsByTransactionGenerationSettings(
			TransactionSettings);
		
		Filter_Settings = ChartsOfCharacteristicTypes.AssetLiabilityItems.SettingsForSelectingItemsOfAssetsLiabilities();
		Filter_Settings.Ref = New Array();
		Filter_Settings.Ref.Add(Record.AccountingObjectDr);
		Filter_Settings.Ref.Add(Record.AccountingObjectCr);
		
		DescriptionOfAccountingObjects = ChartsOfCharacteristicTypes.AssetLiabilityItems.DescriptionOfFinancialAccountingObjects(
			AccountingSettings, Filter_Settings);
		
		DescriptionOfAccountingObject_Dr = DescriptionOfAccountingObjects.Find(Record.AccountingObjectDr, "AccountingObject");
		DescriptionOfAccountingObject_Cr = DescriptionOfAccountingObjects.Find(Record.AccountingObjectCr, "AccountingObject");
		
		If DescriptionOfAccountingObject_Dr = Undefined Then
			ErrorText = StrTemplate(NStr("vi = 'Đối tượng kế toán ""%1"" không được dùng với hệ thống tài khoản và tùy chỉnh bút toán được chọn.';
										|ru = 'Объект учета ""%1"" не используется с выбранными планом счетов и настройкой проводок';
										|en = 'The ""%1"" accounting object is not used with the selected chart of accounts and entry setting'; fa = 'The ""%1"" accounting object is not used with the selected chart of accounts and entry setting';
										|it = 'L''oggetto di contabilità ""%1"" non viene utilizzato con il piano dei conti selezionato e con l''impostazione delle transazioni';
										|pl = 'Obiekt ewidencji ""%1"" nie jest używany z wybranym planem kont i ustawieniem wpisów księgowych';
										|tr = '""%1"" muhasebe nesnesi, seçilen hesap planı ve giriş kurulumuyla kullanılmıyor'"), Record.AccountingObjectDr);
			Common.MessageToUser(ErrorText, RecordKey, "Record.AccountingObjectDr", , Cancel);
		ElsIf DescriptionOfAccountingObject_Dr.ImproperValues Then
			ErrorText = StrTemplate(NStr("vi = 'Đối tượng kế toán ""%1"" không thể tạo đối ứng';
										|ru = 'Объект учета ""%1"" не может образовывать корреспонденцию';
										|en = 'The ""%1"" accounting object cannot generate correspondence'; fa = 'The ""%1"" accounting object cannot generate correspondence';
										|it = 'L''oggetto di contabilità ""%1"" non può formare una corrispondenza';
										|pl = 'Obiekt ewidencji ""%1"" nie może prpzetwarzać korespondencji';
										|tr = '""%1"" muhasebe nesne yazışma oluşturamıyor'"), Record.AccountingObjectDr);
			Common.MessageToUser(ErrorText, RecordKey, "Record.AccountingObjectDr", , Cancel);
		EndIf;
		
		If DescriptionOfAccountingObject_Cr = Undefined Then
			ErrorText = StrTemplate(NStr("vi = 'Đối tượng kế toán ""%1"" không được dùng với hệ thống tài khoản và tùy chỉnh bút toán được chọn.';
										|ru = 'Объект учета ""%1"" не используется с выбранными планом счетов и настройкой проводок';
										|en = 'The ""%1"" accounting object is not used with the selected chart of accounts and entry setting'; fa = 'The ""%1"" accounting object is not used with the selected chart of accounts and entry setting';
										|it = 'L''oggetto di contabilità ""%1"" non viene utilizzato con il piano dei conti selezionato e con l''impostazione delle transazioni';
										|pl = 'Obiekt ewidencji ""%1"" nie jest używany z wybranym planem kont i ustawieniem wpisów księgowych';
										|tr = '""%1"" muhasebe nesnesi, seçilen hesap planı ve giriş kurulumuyla kullanılmıyor'"), Record.AccountingObjectCr);
			Common.MessageToUser(ErrorText, RecordKey, "Record.AccountingObjectCr", , Cancel);
		ElsIf DescriptionOfAccountingObject_Cr.ImproperValues Then
			ErrorText = StrTemplate(NStr("vi = 'Đối tượng kế toán ""%1"" không thể tạo đối ứng';
										|ru = 'Объект учета ""%1"" не может образовывать корреспонденцию';
										|en = 'The ""%1"" accounting object cannot generate correspondence'; fa = 'The ""%1"" accounting object cannot generate correspondence';
										|it = 'L''oggetto di contabilità ""%1"" non può formare una corrispondenza';
										|pl = 'Obiekt ewidencji ""%1"" nie może prpzetwarzać korespondencji';
										|tr = '""%1"" muhasebe nesne yazışma oluşturamıyor'"), Record.AccountingObjectCr);
			Common.MessageToUser(ErrorText, RecordKey, "Record.AccountingObjectCr", , Cancel);
		EndIf;
		
		If Not ValueIsFilled(Record.GLAccountDr) Then
			If Not Record.ItIsNotReflectedInTheAccounts And Not Record.LedgerAccountIsDeterminedByAccountingObjectSetupDr Then
				ErrorText = NStr("vi = 'Chưa điền trường ""Tài khoản Nợ""';
								|ru = 'Не заполнено поле ""Счет Дт""';
								|en = '""Dr account"" is required'; fa = '""Dr account"" is required';
								|it = 'Il campo ""Conto debito"" non è compilato';
								|pl = 'Nie wypełniono pola ""Konto Wn""';
								|tr = '""Hesap Borç"" alanın doldurulmamış'");
				Common.MessageToUser(ErrorText, RecordKey, "Record.GLAccountDr", , Cancel);
			EndIf;
		EndIf;
		
		If Not ValueIsFilled(Record.GLAccountCr) Then
			If Not Record.ItIsNotReflectedInTheAccounts And Not Record.LedgerAccountIsDeterminedByAccountingObjectSetupCr Then
				ErrorText = NStr("vi = 'Chưa điền trường ""Tài khoản Có""';
								|ru = 'Не заполнено поле ""Счет Кт""';
								|en = '""Cr account"" is required'; fa = '""Cr account"" is required';
								|it = 'Il campo ""Conto credito"" non è compilato';
								|pl = 'Nie wypełniono pola ""Konto Ma""';
								|tr = '""Hesap Alacak"" alanın doldurulmamış'");
				Common.MessageToUser(ErrorText, RecordKey, "Record.GLAccountCr", , Cancel);
			EndIf;
		EndIf;
		
		If Record.LedgerAccountIsDeterminedByAccountingObjectSetupDr And Record.LedgerAccountIsDeterminedByAccountingObjectSetupCr Then
			ErrorText = NStr("vi = 'Trong tùy chỉnh phản ánh đối ứng, cần xác định lại ít nhất một tài khoản kế toán, theo bên Nợ hoặc bên Có';
							|ru = 'В настройке отражения корреспонденции необходимо переопределить хотя бы один счет учета, по дебету или по кредиту';
							|en = 'Override at least one ledger account by debit or credit in correspondence recording settings'; fa = 'Override at least one ledger account by debit or credit in correspondence recording settings';
							|it = 'Nell''impostazione di rilevazione della corrispondenza è necessario ridefinire almeno un conto a debito o a credito';
							|pl = 'W ustawieniu odzwierciedlenia korespondencji należy ponownie określić co najmniej jedno konto księgowe dla wn lub dla ma';
							|tr = 'Yazışma yansıması kurulumunda, en az bir defterikebir hesabını borç veya alacak olarak yeniden tanımlamanız gerekir.'");
			Common.MessageToUser(ErrorText, RecordKey, , , Cancel);
		EndIf;
		
	EndDo;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, AttributesNotToCheck);
	
EndProcedure

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If Count() = 1 And Filter.ApplicationProcedure.Use Then
		
		SetLockOnCorrespondenceRecords();
		
		// Adding one setting with the specified order. 
		// It may be necessary to change the order of application in other correspondence settings
		RecordStructure = New Structure;
		For Each Dimension In Metadata().Dimensions Do
			RecordStructure.Insert(Dimension.Name, Filter[Dimension.Name].Value);
		EndDo;
		RecordKey = InformationRegisters.SettingsForReflectingCorrespondenceInFinancialAccounting.CreateRecordKey(RecordStructure);
		
		RecordSet = InformationRegisters.SettingsForReflectingCorrespondenceInFinancialAccounting.CreateRecordSet();
		RecordSet.Filter.ChartOfAccounts.Set(Filter.ChartOfAccounts.Value);
		RecordSet.Filter.PostingGenerationSetting.Set(Filter.PostingGenerationSetting.Value);
		RecordSet.Filter.AccountingObjectDr.Set(Filter.AccountingObjectDr.Value);
		RecordSet.Filter.AccountingObjectCr.Set(Filter.AccountingObjectCr.Value);
		RecordSet.Filter.LongTermDr.Set(Filter.LongTermDr.Value);
		RecordSet.Filter.LongTermCr.Set(Filter.LongTermCr.Value);
		
		RecordSet.Read();
		
		MinimumOrderOfApplication = 1;
		MaximumOrderOfApplication = RecordSet.Count() + 1;
		
		If Filter.ApplicationProcedure.Value < MinimumOrderOfApplication Then
			ErrorText = StrTemplate(NStr("vi = 'Trình tự áp dụng không thể nhỏ hơn %1';
										|ru = 'Порядок применения не может быть меньше %1';
										|en = 'The application order cannot be less than %1'; fa = 'The application order cannot be less than %1';
										|it = 'L''ordine di applicazione non può essere minore di %1';
										|pl = 'Tryb zastosowania nie może być mniejszy niż %1';
										|tr = 'Uygulama sırası %1 değerinden az olamaz'"), MinimumOrderOfApplication);
			Common.MessageToUser(ErrorText, RecordKey, "Record.ApplicationProcedure", , Cancel);
		EndIf;
		
		If Filter.ApplicationProcedure.Value > MaximumOrderOfApplication Then
			ErrorText = StrTemplate(NStr("vi = 'Trình tự nhận không được lớn hơn %1';
										|ru = 'Порядок применения не может быть больше %1';
										|en = 'The application order cannot be greater than %1'; fa = 'The application order cannot be greater than %1';
										|it = 'L''ordine di applicazione non può essere maggiore di %1';
										|pl = 'Tryb zastosowania nie może być większy niż %1';
										|tr = 'Uygulama sırası %1 değerinden fazla olamaz'"), MaximumOrderOfApplication);
			Common.MessageToUser(ErrorText, RecordKey, "Record.ApplicationProcedure", , Cancel);
		EndIf;
		
		If Cancel Then
			Return;
		EndIf;
		
		ApplicationProcedure = Filter.ApplicationProcedure.Value;
		
		For Each Record In RecordSet Do
			
			If Record.ApplicationProcedure = ApplicationProcedure Then
				Record.ApplicationProcedure = Record.ApplicationProcedure + 1;
			EndIf;
			
			ApplicationProcedure = Record.ApplicationProcedure;
			
		EndDo;
		
		If RecordSet.Modified() Then
			RecordSet.Write();
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If Count() = 0
		And ValueIsFilled(Filter.ChartOfAccounts.Value)
		And ValueIsFilled(Filter.PostingGenerationSetting.Value)
		And ValueIsFilled(Filter.AccountingObjectDr.Value)
		And ValueIsFilled(Filter.AccountingObjectCr.Value) Then
		
		SetLockOnCorrespondenceRecords();
		
		// Deleting a setting. It is necessary to update the procedures for applying other settings.
		RecordSet = InformationRegisters.SettingsForReflectingCorrespondenceInFinancialAccounting.CreateRecordSet();
		RecordSet.Filter.ChartOfAccounts.Set(Filter.ChartOfAccounts.Value);
		RecordSet.Filter.PostingGenerationSetting.Set(Filter.PostingGenerationSetting.Value);
		RecordSet.Filter.AccountingObjectDr.Set(Filter.AccountingObjectDr.Value);
		RecordSet.Filter.AccountingObjectCr.Set(Filter.AccountingObjectCr.Value);
		RecordSet.Filter.LongTermDr.Set(Filter.LongTermDr.Value);
		RecordSet.Filter.LongTermCr.Set(Filter.LongTermCr.Value);
		
		RecordSet.Read();
		
		ApplicationProcedure = 1;
		For Each Record In RecordSet Do
			Record.ApplicationProcedure = ApplicationProcedure;
			ApplicationProcedure = ApplicationProcedure + 1;
		EndDo;
		
		If RecordSet.Modified() Then
			RecordSet.Write();
		EndIf;
	
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Procedure SetLockOnCorrespondenceRecords()

	DataLock = New DataLock();
	DataLockItem = DataLock.Add("InformationRegister.SettingsForReflectingCorrespondenceInFinancialAccounting");
	DataLockItem.SetValue("ChartOfAccounts", Filter.ChartOfAccounts.Value);
	DataLockItem.SetValue("PostingGenerationSetting", Filter.PostingGenerationSetting.Value);
	DataLockItem.SetValue("AccountingObjectDr", Filter.AccountingObjectDr.Value);
	DataLockItem.SetValue("AccountingObjectCr", Filter.AccountingObjectCr.Value);
	DataLockItem.SetValue("LongTermDr", Filter.LongTermDr.Value);
	DataLockItem.SetValue("LongTermCr", Filter.LongTermCr.Value);
	DataLockItem.Mode = DataLockMode.Exclusive;
	DataLock.Lock();

EndProcedure


#EndRegion

#EndIf
