#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)
	
	If TypeOf(FillingData) = Type("Structure") Then
		If FillingData.Property("PostingGenerationSetting") Then
			FillingData.Insert("ChartOfAccounts", 
				Common.ObjectAttributeValue(FillingData.PostingGenerationSetting, "Owner"));
		EndIf;
	Else
		FillingData = New Structure();
	EndIf;
	
	If Not FillingData.Property("ChartOfAccounts") Then
		FillingData.Insert("ChartOfAccounts", Catalogs.FinancialAccountingChartsOfAccounts.DefaultChartOfAccounts());
	EndIf;

EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	ManagementCompany = Catalogs.Companies.ManagementCompany;
	
	For Each RegisterRecord In ThisObject Do
		If RegisterRecord.Organization = ManagementCompany
			And Not RegisterRecord.PostingGenerationSetting.IsEmpty() Then
			MessageText = StrTemplate(
				NStr("vi = 'Đối với doanh nghiệp ""%1"", không xem xét sử dụng kế toán tài chính quốc tế.';
					|ru = 'Для организации ""%1"" использование международного финансового учета не предусмотрено.';
					|en = 'Use of financial accounting is not provided for ""%1"" company.'; fa = 'Use of financial accounting is not provided for ""%1"" company.';
					|it = 'Для организации ""%1"" использование международного финансового учета не предусмотрено.';
					|pl = 'Use of financial accounting is not provided for ""%1"" company.';
					|tr = '""%1"" iş yeri için Uluslararası finansal muhasebe sağlanmamıştır.'"),
				ManagementCompany);
			Common.MessageToUser(MessageText,, "Organization",, Cancel);
		EndIf;
	EndDo;
	
	If Not FinancialAccountingOfGeneralPurpose.SettingUpTransactionsForAccountingObjectsOrLocalAccounting() Then
		TransactionGenerationSettings = Unload(, "PostingGenerationSetting").UnloadColumn("PostingGenerationSetting");
		WaysToCancelTransactions = Common.ObjectsAttributeValue(TransactionGenerationSettings, "MethodOfCancelingTransactions");
		
		For Each KeyAndValue In WaysToCancelTransactions Do
			If KeyAndValue.Value = Enums.MethodsOfCancelingPostingsInFinancialAccounting.ByReversePostings Then
				MessageText = NStr("vi = 'Không thể sử dụng tùy chỉnh tạo bút toán với phương thức điều chỉnh bút toán đảo ngược';
									|ru = 'Нельзя использовать настройку формирования проводок со способом корректировки реверсивными проводками';
									|en = 'Cannot use the posting schema with correction by reversing entries'; fa = 'Cannot use the posting schema with correction by reversing entries';
									|it = 'Non utilizzare l''impostazione di creazione delle registrazioni con metodo di correzione tramite registrazioni inverse';
									|pl = 'Nie można używać ustawień tworzenia dekretowań ze sposobem korekty dekretowaniami rewersyjnymi';
									|tr = 'Girişleri tersine çevirerek düzenleme yöntemiyle giriş oluşturma ayarını kullanamazsınız'");
				Common.MessageToUser(MessageText,, "PostingGenerationSetting",, Cancel);
			EndIf;
		EndDo;
	EndIf;

EndProcedure

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);

EndProcedure

#EndRegion

#EndIf
