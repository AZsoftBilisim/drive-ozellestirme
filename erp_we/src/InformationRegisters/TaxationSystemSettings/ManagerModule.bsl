#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Returns the default values for register resources.
// The key names of the structure should strictly correspond to the resource names in the register.
// 
// Returns:
// 	Structure - the structure of register resource values.
Function DefaultValues() Export
	StructureOfValues = New Structure;
	StructureOfValues.Insert("TaxationSystem", Enums.TaxationSystems.Shared3);
	StructureOfValues.Insert("CompanyIsAUTIIPayer", False);
	StructureOfValues.Insert("ThisIsAMETPayerAtRate", False);
	StructureOfValues.Insert("PayerOfAdditionalIncomeTaxFromHydrocarbonProductionAIT", False);
	StructureOfValues.Insert("STSIsApplied", False);
	StructureOfValues.Insert("IncomeTaxPayer", False);
	StructureOfValues.Insert("DateOfTransferToSTS", Undefined);
	StructureOfValues.Insert("STSTransitionNotificationNo", Undefined);
	StructureOfValues.Insert("NotificationDateSTS", Undefined);
	StructureOfValues.Insert("PTSIsApplied", False);
	StructureOfValues.Insert("ASTSIsApplied", False);
	StructureOfValues.Insert("STPPayer", False);
	StructureOfValues.Insert("AccountingPoliciesExist", False);
	
	Return StructureOfValues
EndFunction

// Returns the request text based on the register data.
// 
// Returns:
// 	String - query text.
Function QueryTextCurrentTaxAccountingPolicySettings() Export
	QueryText = "
	|SELECT ALLOWED
	|	CASE WHEN SliceTable.Period IS NULL THEN
	|		FALSE
	|	ELSE
	|		TRUE
	|	END AS AccountingPoliciesExist,
	|	SliceTable.Period AS Period,
	|	ParentOrganizations.BranchOffice AS Organization,
	|	SliceTable.TaxationSystem AS TaxationSystem,
	|	SliceTable.CompanyIsAUTIIPayer AS CompanyIsAUTIIPayer,
	|	SliceTable.STSIsApplied AS STSIsApplied,
	|	SliceTable.IncomeTaxPayer AS IncomeTaxPayer,
	|	SliceTable.ThisIsAMETPayerAtRate AS ThisIsAMETPayerAtRate,
	|	SliceTable.DateOfTransferToSTS AS DateOfTransferToSTS,
	|	SliceTable.STSTransitionNotificationNo AS STSTransitionNotificationNo,
	|	SliceTable.NotificationDateSTS AS NotificationDateSTS,
	|	(CASE
	|		WHEN SliceTable.TaxationSystem = VALUE(Enum.TaxationSystems.Shared3)
	|			THEN VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|		ELSE VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT) END) AS DefaultVATTaxation,
	|	SliceTable.PTSIsApplied AS PTSIsApplied,
	|	SliceTable.ASTSIsApplied AS ASTSIsApplied,
	|	SliceTable.PayerOfAdditionalIncomeTaxFromHydrocarbonProductionAIT AS PayerOfAdditionalIncomeTaxFromHydrocarbonProductionAIT,
	|	SliceTable.STPPayer AS STPPayer
	|FROM
	|	TTParentOrganizations AS ParentOrganizations
	|		LEFT JOIN InformationRegister.TaxationSystemSettings.SliceLast(&Period, Organization IN
	|			(SELECT
	|				ParentOrganizations.Organization
	|			FROM
	|				TTParentOrganizations AS ParentOrganizations)) AS SliceTable
	|		ON ParentOrganizations.Organization = SliceTable.Organization
	|";
	
	Return QueryText
	
EndFunction

// Generates a text description of the set parameters.
// 
// Parameters:
// 	Organization - CatalogRef.Companies - link to the organization.
// 	ValidityDate - Date - period of validity of settings.
// 	CurrentSettings_ - Structure - the parameters of the accounting policies.
// 	All - Boolean - if True, it returns a description of all settings.
// Returns:
// 	String - Description of the current parameters in a string.
Function DescriptionOfActiveParameters(Organization, ValidityDate = Undefined, CurrentSettings_ = Undefined, All = False) Export
	
	If CurrentSettings_ = Undefined Then
		CurrentSettings_ = AccountingPoliciesTaxSettings.CurrentParametersOfTaxesAndAccountingPoliciesAsOfDate(
			"TaxationSystemSettings",
			Organization,
			ValidityDate,
			False);
	EndIf;
	StringPattern_ = "%1: %2." + Chars.LF;
	StringPatternBoolean = "%1." + Chars.LF;
	If Not ValueIsFilled(CurrentSettings_) Then
		SettingsDescriptionString = NStr("vi = 'Chưa xác định tham số.';
										|ru = 'Не заданы параметры.';
										|en = 'Parameters are not specified.'; fa = 'پارامترها مشخص نشده‌اند.';
										|it = 'I parametri non sono imposatti.';
										|pl = 'Nie są ustawione parametry.';
										|tr = 'Parametreler belirtilmedi.'");
		Return SettingsDescriptionString;
	EndIf;
	
	SettingsDescriptionString = StrTemplate(StringPattern_, 
		NStr("vi = 'Hệ thống thuế';
			|ru = 'Система налогообложения';
			|en = 'Taxation system'; fa = 'نظام مالیاتی';
			|it = 'Sistema di tassazione';
			|pl = 'System opodatkowania';
			|tr = 'Vergilendirme sistemi'"),
		CurrentSettings_.TaxationSystem);
	
	If CurrentSettings_.CompanyIsAUTIIPayer Or All Then
		SettingsDescriptionString = SettingsDescriptionString
			+ StrTemplate(StringPatternBoolean,
				NStr("vi = 'Doanh nghiệp là người nộp thuế khoán';
					|ru = 'Организация является плательщиком ЕНВД';
					|en = 'Company is a UTII payer'; fa = 'شرکت پرداخت‌کننده UTII است';
					|it = 'Azienda è contribuente dell''Imposta unica sul reddito imputato';
					|pl = 'Firma jest płatnikiem Jednolitego podatku od przypisanych dochodów';
					|tr = 'İş yeri EGTV mükellefidir'"));
	EndIf;
	
	If CurrentSettings_.ThisIsAMETPayerAtRate Or All Then
		SettingsDescriptionString = SettingsDescriptionString
			+ StrTemplate(StringPatternBoolean,
				NStr("vi = 'Là người nộp thuế GTGT theo thuế suất';
					|ru = 'Является плательщиком НДПИ по процентной ставке';
					|en = 'This is a MET payer at rate'; fa = 'این پرداخت‌کننده MET با نرخ است';
					|it = 'È un contribuente per l''imposta sull''estrazione mineraria con aliquota';
					|pl = 'Jest płatnikiem PWKU według stawki procentowej';
					|tr = 'Faiz oranı üzerinden MÇV mükellefidir'"));
	EndIf;
	
	If CurrentSettings_.PTSIsApplied Or All Then
		SettingsDescriptionString = SettingsDescriptionString
			+ StrTemplate(StringPatternBoolean,
				NStr("vi = 'Tổ chức áp dụng hệ thống đánh thuế bằng sáng chế (PSN)';
					|ru = 'Организация применяет патентную систему налогообложения (ПСН)';
					|en = 'Company applies the patent taxation system (PTS)'; fa = 'شرکت نظام مالیاتی پروانه (PTS) را اعمال می‌کند';
					|it = 'L''organizazzione applica il sistema di tassazione dei brevetti (PNS)';
					|pl = 'Firma stosuje patentowy system opodatkowania';
					|tr = 'İş yeri, patent vergilendirme sistemini (PVS) uygulamaktadır'"));
	EndIf;
	
	If CurrentSettings_.PayerOfAdditionalIncomeTaxFromHydrocarbonProductionAIT And CalculationOfCostLocalization.GetFunctionalOptionAITAccounting() Then
		SettingsDescriptionString = SettingsDescriptionString
			+ StrTemplate(StringPatternBoolean,
				NStr("vi = 'Doanh nghiệp là người nộp thuế thu nhập bổ sung';
					|ru = 'Организация является плательщиком НДД';
					|en = 'The company is an AIT payer'; fa = 'The company is an AIT payer';
					|it = 'Организация является плательщиком НДД';
					|pl = 'The company is an AIT payer';
					|tr = 'İş yeri EGV mükellefidir'"));
	EndIf;
	
	If CurrentSettings_.TaxationSystem = Enums.TaxationSystems.Simplified Or All Then
		If ValueIsFilled(CurrentSettings_.DateOfTransferToSTS) Or All Then
			SettingsDescriptionString = SettingsDescriptionString
				+ StrTemplate(StringPattern_,
					NStr("vi = 'Ngày chuyển sang hệ thống ThGL';
						|ru = 'Дата перехода на УСН';
						|en = 'Date of transfer to STS'; fa = 'تاریخ انتقال به STS';
						|it = 'Data di passaggio al regime fiscale semplificato';
						|pl = 'Data przejścia na USO';
						|tr = 'BVS''ye geçiş tarihi'"),
					Format(CurrentSettings_.DateOfTransferToSTS,"DLF=DD;"));
		EndIf;
		
		If ValueIsFilled(CurrentSettings_.STSTransitionNotificationNo) Or All Then
			SettingsDescriptionString = SettingsDescriptionString
				+ StrTemplate(StringPattern_,
					NStr("vi = 'Thông báo chuyển sang hệ thống ThGL số';
						|ru = 'Уведомление о переходе на УСН №';
						|en = 'STS transition notification No.'; fa = 'شماره اعلان انتقال به STS';
						|it = 'Notifica di passaggio al regime fiscale semplificato №';
						|pl = 'Powiadomienie o przejściu na USO nr';
						|tr = 'BVS No. üzerine geçiş bildirimi'"),
					CurrentSettings_.STSTransitionNotificationNo);
		EndIf;
		
		If ValueIsFilled(CurrentSettings_.NotificationDateSTS) Or All Then
			SettingsDescriptionString = SettingsDescriptionString
				+ StrTemplate(StringPattern_,
					NStr("vi = 'Ngày thông báo chuyển đổi sang hệ thống ThGL';
						|ru = 'Дата уведомления о переходе на УСН';
						|en = 'STS transition notification date'; fa = 'STS transition notification date';
						|it = 'Data della notifica di passaggio al regime fiscale semplificato';
						|pl = 'Data powiadomienia o przejściu na USO';
						|tr = 'BVS''e geçiş bildirim tarihi'"),
					Format(CurrentSettings_.NotificationDateSTS,"DLF=DD;"));
		EndIf;
		
	EndIf;
	
	If CurrentSettings_.STPPayer Or All Then
		SettingsDescriptionString = SettingsDescriptionString
			+ StrTemplate(StringPatternBoolean,
				NStr("vi = 'Doanh nghiệp sử dụng dịch vụ nộp thuế một lần khi thanh toán thuế';
					|ru = 'Организация использует единый налоговый платеж при уплате налогов';
					|en = 'The company uses a unified tax payment when paying taxes'; fa = 'The company uses a unified tax payment when paying taxes';
					|it = 'L''azienda utilizza un singolo pagamento fiscale al pagamento delle imposte';
					|pl = 'Firma używa jednolitej płatności przy opłacie podatków';
					|tr = 'İş yeri vergi öderken tek bir vergi ödemesi kullanır'"));
	EndIf;
	
	Return SettingsDescriptionString
EndFunction

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Organization)";

EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#EndIf
