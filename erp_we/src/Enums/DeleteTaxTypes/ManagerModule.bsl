#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Gets a link to the Catalog of tax types of contributions by tax transfer type.
// 
// Parameters:
//  TaxType - EnumRef.DeleteTaxTypes
// 
// Returns:
//  CatalogRef.TaxContributionKinds - Link Types Of Taxes Contributions By Type Of Taxes
Function LinkTypesOfTaxesContributionsByTypeOfTaxes(TaxType) Export
	If Not TypeOf(TaxType) = Type("EnumRef.DeleteTaxTypes") Then
		Return TaxType;
	EndIf;
	If TaxType = Enums.DeleteTaxTypes.EmptyRef() Then
		Return Catalogs.TaxContributionKinds.EmptyRef();
	EndIf;
	IndexOf = Enums.DeleteTaxTypes.IndexOf(TaxType);
	EnumerationMetadata = TaxType.Metadata().EnumValues[IndexOf];
	Ref = Catalogs.TaxContributionKinds.GetLinkOfPredefinedElement(EnumerationMetadata.Name);
	Return Ref;
EndFunction

// Fills in the value of the new Attribute of an Object with the Catalog type.Tax 
// types based on the old Attributes with the Enumeration type that are being deleted.Delete tax types.
// 
// Parameters:
//  Object - Document object, Reference object
//	OldAttributes - String
//	NewAttribute - String
Procedure FillInTaxTypeAttributes(Object, OldAttributes, NewAttribute = Undefined) Export
	
	PathArray = StrSplit(OldAttributes, ".");
	IsTabularSection = PathArray.Count() = 2;
	
	If IsTabularSection Then
		TabularSectionName = PathArray[0];
		OldAttributes = PathArray[1];
		For Each String In Object[TabularSectionName] Do
			If NewAttribute = Undefined Then
				String[OldAttributes] = LinkTypesOfTaxesContributionsByTypeOfTaxes(String[OldAttributes]);
			Else 
				String[NewAttribute] = LinkTypesOfTaxesContributionsByTypeOfTaxes(String[OldAttributes]);
				String[OldAttributes] = Undefined;
			EndIf;
		EndDo;
	Else
		If NewAttribute = Undefined Then
			Object[OldAttributes]= LinkTypesOfTaxesContributionsByTypeOfTaxes(Object[OldAttributes]);
		Else
			Object[NewAttribute]= LinkTypesOfTaxesContributionsByTypeOfTaxes(Object[OldAttributes]);
			Object[OldAttributes] = Undefined;
		EndIf;
	EndIf;
EndProcedure

// Name of the predefined element.
// 
// Parameters:
//  PredefinedItemName - String - Name of the predefined element
// 
// Returns:
//  String - Name Of The Predefined Element
Function NameOfPredefinedElement(PredefinedItemName) Export
	If PredefinedItemName = "SingleTaxPayment" Then
		Return "vi = 'Nộp thuế một lần';
				|ru = 'Единый налоговый платеж';
				|en = 'Unified tax payment';
				|it = 'Единый налоговый платеж';
				|pl = 'Jednolita płatność podakowa';
				|tr = 'Tek vergi ödemesi'"; // @NStr-1
	ElsIf PredefinedItemName = "UTII" Then
		Return "vi = 'Thuế khoán';
				|ru = 'ЕНВД';
				|en = 'UTII';
				|it = 'ЕНВД';
				|pl = 'UTII';
				|tr = 'EGTV'"; // @NStr-1
	ElsIf PredefinedItemName = "SAT" Then
		Return "vi = 'Thuế nông nghiệp';
				|ru = 'ЕСХН';
				|en = 'UAT';
				|it = 'ЕСХН';
				|pl = 'UAT';
				|tr = 'TTV'"; // @NStr-1
	ElsIf PredefinedItemName = "LandValueTax" Then
		Return "vi = 'Thuế đất';
				|ru = 'Земельный налог';
				|en = 'Land value tax';
				|it = 'Земельный налог';
				|pl = 'Podatek gruntowy';
				|tr = 'Arazi vergisi'"; // @NStr-1
	ElsIf PredefinedItemName = "CorporatePropertyTax" Then
		Return "vi = 'Thuế tài sản của doanh nghiệp';
				|ru = 'Налог на имущество организаций';
				|en = 'Corporate property tax';
				|it = 'Налог на имущество организаций';
				|pl = 'Podatek majątkowy firmy';
				|tr = 'İş yeri emlak vergisi'"; // @NStr-1
	ElsIf PredefinedItemName = "IncomeTaxRegionalBudget" Then
		Return "vi = 'Thuế thu nhập, ngân sách tỉnh, thành';
				|ru = 'Налог на прибыль, региональный бюджет';
				|en = 'Income tax, regional budget';
				|it = 'Налог на прибыль, региональный бюджет';
				|pl = 'Podatek od zysków, budżet regionalny';
				|tr = 'Gelir vergisi, bölgesel bütçe'"; // @NStr-1
	ElsIf PredefinedItemName = "IncomeTaxFederalBudget" Then
		Return "vi = 'Thuế thu nhập, ngân sách nhà nước';
				|ru = 'Налог на прибыль, федеральный бюджет';
				|en = 'Income tax, federal budget';
				|it = 'Налог на прибыль, федеральный бюджет';
				|pl = 'Podatek od zysków, budżet federalny';
				|tr = 'Gelir vergisi, federal bütçe'"; // @NStr-1
	ElsIf PredefinedItemName = "IncomeTax_TaxAgent" Then
		Return "vi = 'Thuế thu nhập khi thực hiện các nghĩa vụ của đại lý thuế';
				|ru = 'Налог на прибыль при исполнении обязанностей налогового агента';
				|en = 'Income tax when acting as a tax agent';
				|it = 'Налог на прибыль при исполнении обязанностей налогового агента';
				|pl = 'Income tax when acting as a tax agent';
				|tr = 'Vergi memurunun görevlerini yerine getirdiğindeki gelir vergisi'"; // @NStr-1
	ElsIf PredefinedItemName = "VAT" Then
		Return "vi = 'Thuế GTGT';
				|ru = 'НДС';
				|en = 'VAT';
				|it = 'НДС';
				|pl = 'VAT';
				|tr = 'KDV'"; // @NStr-1
	ElsIf PredefinedItemName = "VAT_ImportedGoods" Then
		Return "vi = 'Thuế GTGT khi nhập khẩu hàng hóa từ EAEU';
				|ru = 'НДС при импорте товаров из ЕАЭС';
				|en = 'VAT on goods import from EAEU';
				|it = 'НДС при импорте товаров из ЕАЭС';
				|pl = 'VAT od importu towarów z EWG';
				|tr = 'AEB üzerinden ürün ithalatındaki KDV'"; // @NStr-1
	ElsIf PredefinedItemName = "VAT_TaxAgent" Then
		Return "vi = 'Thuế GTGT khi thực hiện nghĩa vụ của đại lý thuế';
				|ru = 'НДС при исполнении обязанностей налогового агента';
				|en = 'VAT when acting as a tax agent';
				|it = 'НДС при исполнении обязанностей налогового агента';
				|pl = 'VAT podczas wykonania obowiązków agenta podatkowego';
				|tr = 'Vergi memurunun görevlerini yerine getirirken KDV'"; // @NStr-1
	ElsIf PredefinedItemName = "PERSONALINCOMETAX" Then
		Return "vi = 'Thuế TNCN khi thực hiện nghĩa vụ của đại lý thuế';
				|ru = 'НДФЛ при исполнении обязанностей налогового агента';
				|en = 'Personal income tax while performing the tax agent duties';
				|it = 'НДФЛ при исполнении обязанностей налогового агента';
				|pl = 'PIT dla wykonania obowiązków agenta podatkowego';
				|tr = 'Vergi memurunun görevlerini yerine getirirken KMGV'"; // @NStr-1
	ElsIf PredefinedItemName = "IndividualEntrepreneurPersonalIncomeTax" Then
		Return "vi = 'Thuế TNCN của cá nhân kinh doanh ';
				|ru = 'НДФЛ индивидуального предпринимателя ';
				|en = 'Individual entrepreneur personal income tax ';
				|it = 'НДФЛ индивидуального предпринимателя ';
				|pl = 'PIT przedsiębiorcy prywatnego';
				|tr = 'Şahıs şirketine ait kişisel gelir vergisi'"; // @NStr-1
	ElsIf PredefinedItemName = "OtherTaxesAndCharges" Then
		Return "vi = 'Thuế và bảo hiểm khác';
				|ru = 'Прочие налоги и сборы';
				|en = 'Other taxes and charges';
				|it = 'Прочие налоги и сборы';
				|pl = 'Inne podatki i opłaty';
				|tr = 'Diğer vergi ve harçlar'"; // @NStr-1
	ElsIf PredefinedItemName = "SalesCharge" Then
		Return "vi = 'Phí bán hàng';
				|ru = 'Торговый сбор';
				|en = 'Sales charge';
				|it = 'Торговый сбор';
				|pl = 'Opłata handlowa';
				|tr = 'Ticaret ücreti'"; // @NStr-1
	ElsIf PredefinedItemName = "CompanyTransportTax" Then
		Return "vi = 'Thuế vận chuyển của doanh nghiệp';
				|ru = 'Транспортный налог организаций';
				|en = 'Company vehicle tax ';
				|it = 'Транспортный налог организаций';
				|pl = 'Podatek transportowy firm';
				|tr = 'İş yeri araç vergisi'"; // @NStr-1
	ElsIf PredefinedItemName = "STSTaxIncome" Then
		Return "vi = 'Thuế khi Hệ thống thuế giản lược (thu nhập)';
				|ru = 'Налог при УСН (доходы)';
				|en = 'STS tax (income)';
				|it = 'Налог при УСН (доходы)';
				|pl = 'Podatek przy USO (Uproszczony System Opodatkowania) (dochody)';
				|tr = 'BVS kapsamında vergi (gelirler)'"; // @NStr-1
	ElsIf PredefinedItemName = "STSTaxIncomeMinusExpenses" Then
		Return "vi = 'Thuế khi Hệ thống thuế giản lược (thu nhập trừ chi phí)';
				|ru = 'Налог при УСН (доходы минус расходы)';
				|en = 'STS tax (income minus expenses)';
				|it = 'Налог при УСН (доходы минус расходы)';
				|pl = 'Podatek przy USO (dochody minus rozchody)';
				|tr = 'BVS kapsamında vergi (gelirler eksi giderler)'"; // @NStr-1
	ElsIf PredefinedItemName = "MinimumSTSTax" Then
		Return "vi = 'Thuế tối thiểu Hệ thống thuế giản lược';
				|ru = 'Минимальный налог УСН';
				|en = 'Minimum STS tax';
				|it = 'Минимальный налог УСН';
				|pl = 'Minimalny podatek USO';
				|tr = 'Minimum BVS vergisi'"; // @NStr-1
	ElsIf PredefinedItemName = "PensionFundByOverallTariff" Then
		Return "vi = 'Quỹ hưu - theo tổng mức lương từ ngày 1 tháng 1 năm 2014';
				|ru = 'ПФР - по суммарному тарифу с 1 января 2014 года';
				|en = 'Pension Fund: by overall tariff from January 1, 2014';
				|it = 'ПФР - по суммарному тарифу с 1 января 2014 года';
				|pl = 'ZUS w łącznej taryfie od 1 stycznia 2014 r';
				|tr = 'RES; 1 Ocak 2014 tarihinden itibaren toplam destek planında'"; // @NStr-1
	ElsIf PredefinedItemName = "InsuranceContributionsToPensionFund" Then
		Return "vi = 'Phí bảo hiểm nộp vào Quỹ hưu';
				|ru = 'Страховые взносы в ПФР';
				|en = 'Insurance contributions to Pension Fund';
				|it = 'Страховые взносы в ПФР';
				|pl = 'Składki ubezpieczeniowe do FER';
				|tr = 'RES sigorta primleri'"; // @NStr-1
	ElsIf PredefinedItemName = "InsuranceContributionsToPensionFundFundedComponentBefore2014" Then
		Return "vi = 'Phí bảo hiểm nộp vào Quỹ hưu, phần đã tính (đến năm 2014)';
				|ru = 'Страховые взносы в ПФР, накопительная часть (до 2014 г.)';
				|en = 'Insurance contributions to Pension Fund, funded component (before 2014)';
				|it = 'Страховые взносы в ПФР, накопительная часть (до 2014 г.)';
				|pl = 'Składki ubezpieczeniowe do ZUS, część kumulacyjna (do 2014 r.)';
				|tr = 'RES sigorta primleri, finanse edilen kısım (2014 yılına kadar)'"; // @NStr-1
	ElsIf PredefinedItemName = "ContributionsToPensionSupplementsForAircrewMembers" Then
		Return "vi = 'Các khoản khấu trừ thanh toán bổ sung lương hưu cho các thành viên phi đoàn bay';
				|ru = 'Взносы на выплату доплат к пенсии членам летных экипажей';
				|en = 'Contributions to pension supplements for aircrew members';
				|it = 'Взносы на выплату доплат к пенсии членам летных экипажей';
				|pl = 'Składki na wypłatę dopłat do emerytury członkom załóg statków latających';
				|tr = 'Uçuş ekibi üyelerine emekli maaşlarına ek ödemelerin ödenmesi için primler'"; // @NStr-1
	ElsIf PredefinedItemName = "ContributionsToPensionFundExtraTariffForMiners" Then
		Return "vi = 'Các khoản khấu trừ nộp vào Quỹ hưu (mức bổ sung của thợ mỏ)';
				|ru = 'Взносы в ПФР (дополнительный тариф шахтеров)';
				|en = 'Contributions to Pension Fund (extra tariff for miners)';
				|it = 'Взносы в ПФР (дополнительный тариф шахтеров)';
				|pl = 'Składki ZUS (dodatkowa taryfa górników)';
				|tr = 'RES primleri (madenciler için ek destek planı)'"; // @NStr-1
	ElsIf PredefinedItemName = "PFEmployedOnUndergroundAndHarmfulJobs" Then
		Return "vi = 'Các khoản khấu trừ nộp vào Quỹ hưu (mức bổ sung khi làm việc với điều kiện lao động độc hại)';
				|ru = 'Взносы в ПФР (дополнительный тариф за занятых на работах с вредными условиями труда)';
				|en = 'Contributions to Pension Fund (extra tariff for employees involved in activities with harmful working conditions)';
				|it = 'Взносы в ПФР (дополнительный тариф за занятых на работах с вредными условиями труда)';
				|pl = 'Składki ZUS (dodatkowa taryfa za zatrudnionych na pracach szkodliwych dla zdrowia)';
				|tr = 'RES primleri (zararlı çalışma koşullarında çalışanlar için ek destek planı)'"; // @NStr-1
	ElsIf PredefinedItemName = "PFForEmployedOnHeavyAndOtherJobs" Then
		Return "vi = 'Các khoản khấu trừ nộp vào Quỹ hưu (mức bổ sung khi làm việc với điều kiện lao động nặng nhọc)';
				|ru = 'Взносы в ПФР (дополнительный тариф за занятых на работах с тяжелыми условиями труда)';
				|en = 'Contributions to Pension Fund (extra tariff for employees involved in activities with arduous working conditions)';
				|it = 'Взносы в ПФР (дополнительный тариф за занятых на работах с тяжелыми условиями труда)';
				|pl = 'Składki do ZUS (dodatkowa taryfa za zatrudnionych na pracach z ciężkimi warunkami)';
				|tr = 'RES primleri (ağır çalışma koşullarında çalışanlar için ek destek planı)'"; // @NStr-1
	ElsIf PredefinedItemName = "PensionFundFromBaseInExcessOfLimitValue" Then
		Return "vi = 'Quỹ hưu - từ cơ sở đến vượt quá giá trị giới hạn, từ 1 tháng 1 năm 2016';
				|ru = 'ПФР - с базы сверх предельной величины, с 1 января 2016 года';
				|en = 'Pension Fund: from base in excess of limit value from January 1, 2016';
				|it = 'ПФР - с базы сверх предельной величины, с 1 января 2016 года';
				|pl = 'ZUS powyżej wartości progowej, od 1 styczna 2016 roku';
				|tr = 'RES; 1 Ocak 2016 tarihinden itibaren limitin üstündeki tabandan'"; // @NStr-1
	ElsIf PredefinedItemName = "INSURANCECONTRIBUTIONSTOFCMIF" Then
		Return "vi = 'Phí bảo hiểm nộp vào Quỹ bảo hiểm y tế bắt buộc';
				|ru = 'Страховые взносы в ФФОМС';
				|en = 'Insurance contributions to FCMIF';
				|it = 'Страховые взносы в ФФОМС';
				|pl = 'Składki ubezpieczeniowe do ZUS';
				|tr = 'FZSSF sigorta primleri'"; // @NStr-1
	ElsIf PredefinedItemName = "TCMIF" Then
		Return "vi = 'Quỹ bảo hiểm y tế bắt buộc theo khu vực';
				|ru = 'ТФОМС';
				|en = 'TCMIF';
				|it = 'ТФОМС';
				|pl = 'TCMIF';
				|tr = 'BZSSF'"; // @NStr-1
	ElsIf PredefinedItemName = "INSURANCECONTRIBUTIONSTOSSF" Then
		Return "vi = 'Phí bảo hiểm nộp vào Quỹ bảo hiểm xã hội';
				|ru = 'Страховые взносы в ФСС';
				|en = 'Insurance contributions to SIF';
				|it = 'Страховые взносы в ФСС';
				|pl = 'Składki ubezpieczeniowe do ZUS';
				|tr = 'SGF sigorta primleri'"; // @NStr-1
	ElsIf PredefinedItemName = "ACCIDENTINSURANCECONTRIBUTIONSTOSSF" Then
		Return "vi = 'Phí bảo hiểm do tai nạn';
				|ru = 'Страховые взносы от несчастных случаев';
				|en = 'Accident insurance contributions';
				|it = 'Страховые взносы от несчастных случаев';
				|pl = 'Accident insurance contributions';
				|tr = 'Kaza sigortası primleri'"; // @NStr-1
	ElsIf PredefinedItemName = "PersonalIncomeTaxOnCounterpartyIncome" Then
		Return "vi = 'Thuế TNCN từ thu nhập của đối tác';
				|ru = 'НДФЛ с доходов контрагентов';
				|en = 'Personal income tax on counterparty income';
				|it = 'НДФЛ с доходов контрагентов';
				|pl = 'PIT z dochodów kontrahentów';
				|tr = 'Cari hesapların gelirlerine ilişkin KMGV'"; // @NStr-1
	ElsIf PredefinedItemName = "PersonalIncomeTaxOnDividends" Then
		Return "vi = 'Thuế TNCN từ cổ tức';
				|ru = 'НДФЛ с дивидендов';
				|en = 'Personal income tax on dividends';
				|it = 'НДФЛ с дивидендов';
				|pl = 'PIT z dywidend';
				|tr = 'Temettüler üzerinden KMGV'"; // @NStr-1
	ElsIf PredefinedItemName = "PersonalIncomeTaxOnDividendsToEmployees" Then
		Return "vi = 'Thuế TNCN từ cổ tức cho người lao động';
				|ru = 'НДФЛ с дивидендов работникам';
				|en = 'Personal income tax on dividends to employees';
				|it = 'НДФЛ с дивидендов работникам';
				|pl = 'PIT z dywidend pracownikom';
				|tr = 'Çalışanlara ödenen temettüler üzerinden KMGV'"; // @NStr-1
	ElsIf PredefinedItemName = "PersonalIncomeTaxAccruedAdditionallyAfterCheck" Then
		Return "vi = 'Thuế TNCN được tính toán theo kết quả kiểm tra';
				|ru = 'НДФЛ, доначисленный по результатам проверки';
				|en = 'Personal income tax accrued additionally after the check';
				|it = 'НДФЛ, доначисленный по результатам проверки';
				|pl = 'PIT, doliczony wg. wyników kontroli';
				|tr = 'Kontrol sonuçları doğrultusunda tahakkuk eden KMGV'"; // @NStr-1
	ElsIf PredefinedItemName = "PersonalIncomeTaxTransferDebtToTaxAuthority" Then
		Return "vi = 'Thuế TNCN chuyển nợ vào cơ quan thuế';
				|ru = 'НДФЛ передача задолженности в налоговый орган';
				|en = 'Personal income tax transfer debt to the tax authority';
				|it = 'НДФЛ передача задолженности в налоговый орган';
				|pl = 'PIT przekazanie zadłużenia do organu podatkowego';
				|tr = 'KMGV borcunun vergi dairesine transferi'"; // @NStr-1
	ElsIf PredefinedItemName = "PersonalIncomeTaxOnIncomeOfOtherTransactionsWithPersonnel" Then
		Return "vi = 'Thuế TNCN từ thu nhập theo các giao dịch khác với cá nhân';
				|ru = 'НДФЛ с доходов по прочим операциям с персоналом';
				|en = 'Personal income tax on income from other transactions with personnel';
				|it = 'НДФЛ с доходов по прочим операциям с персоналом';
				|pl = 'PIT z dochodów wg. innych operacji z personelem';
				|tr = 'Personelle yapılan diğer işlemlerden elde edilen gelir üzerinden KMGV'"; // @NStr-1
	ElsIf PredefinedItemName = "PersonalIncomeTaxOnIncomeInExcessOfMaximumAmountCalculatedByTaxAgent" Then
		Return "vi = 'Thuế thu nhập cá nhân đối với thu nhập vượt quá mức tối đa do đại lý thuế tính ';
				|ru = 'НДФЛ с доходов свыше предельной величины, исчисленный налоговым агентом';
				|en = 'Personal income tax on income in excess of the maximum amount calculated by the tax agent';
				|it = 'НДФЛ с доходов свыше предельной величины, исчисленный налоговым агентом';
				|pl = 'PIT z dochodów ponad określonego rozmiaru, obliczonego przez agenta podatkowego';
				|tr = 'Vergi memuru tarafından hesaplanan, sınırın üzerindeki gelir üzerinden KMGV'"; // @NStr-1
	ElsIf PredefinedItemName = "PersonalIncomeTaxDividendsFromExcess" Then
		Return "vi = 'Thuế TNCN có cổ tức cao hơn giá trị biên';
				|ru = 'НДФЛ с дивидендов свыше предельной величины';
				|en = 'PIT from dividends above limit value';
				|it = 'НДФЛ с дивидендов свыше предельной величины';
				|pl = 'PIT from dividends above limit value';
				|tr = 'Azami tutarın üzerindeki temettüler için kişisel gelir vergisi'"; // @NStr-1
	ElsIf PredefinedItemName = "PensionFundFromBaseToLimitValue" Then
		Return "vi = 'Quỹ hưu - từ cơ sở đến vượt quá giá trị giới hạn';
				|ru = 'ПФР - с базы до предельной величины';
				|en = 'Pension Fund: from base to the limit value';
				|it = 'ПФР - с базы до предельной величины';
				|pl = 'ZUS - z bazy powyżej wartości progowej';
				|tr = 'RES; tabandan sınır değere'"; // @NStr-1
	ElsIf PredefinedItemName = "VAT_ReverseTaxation" Then
		Return "vi = 'Thuế GTGT của đại lý thuế theo các dạng hàng hóa riêng';
				|ru = 'НДС налогового агента по отдельным видам товаров';
				|en = 'Tax agent VAT by particular goods kinds';
				|it = 'НДС налогового агента по отдельным видам товаров';
				|pl = 'VAT agenta podatkowego według oddzielnych rodzajów towarów';
				|tr = 'Belirli ürün türleri için bir vergi memurunun KDV''si'"; // @NStr-1
	ElsIf PredefinedItemName = "ASTSTAX" Then
		Return "vi = 'Thuế trong hệ thống thuế giản lược tự động hóa';
				|ru = 'Налог при АУСН';
				|en = 'ASTS tax';
				|it = 'Налог при АУСН';
				|pl = 'Podatek przy zautomatyzowanym uproszczonym systemie opodatkowania';
				|tr = 'BOVS kapsamında vergi'"; // @NStr-1
	ElsIf PredefinedItemName = "InsuranceContributionsAtJointRate" Then
		Return "vi = 'Phí bảo hiểm theo biểu phí duy nhất';
				|ru = 'Страховые взносы по единому тарифу';
				|en = 'Insurance contributions at joint rate';
				|it = 'Страховые взносы по единому тарифу';
				|pl = 'Składki ubezpieczeniowe zgodnie z jedyną taryfą';
				|tr = 'Tek destek planı kapsamında sigorta primleri'"; // @NStr-1
	ElsIf PredefinedItemName = "ContributionsForPensionInsuranceOfForeignEmployees" Then
		Return "vi = 'Phí bảo hiểm thất nghiệp của lao động nước ngoài';
				|ru = 'Взносы на пенсионное страхование иностранных работников';
				|en = 'Contributions for pension insurance of foreign employees';
				|it = 'Взносы на пенсионное страхование иностранных работников';
				|pl = 'Contributions for pension insurance of foreign employees';
				|tr = 'Yabancı işçilerin emeklilik sigortası primleri'"; // @NStr-1
	ElsIf PredefinedItemName = "ContributionsForMedicalInsuranceOfForeignEmployees" Then
		Return "vi = 'Phí bảo hiểm y tế của lao động nước ngoài';
				|ru = 'Взносы на медицинское страхование иностранных работников';
				|en = 'Contributions for medical insurance of foreign employees';
				|it = 'Взносы на медицинское страхование иностранных работников';
				|pl = 'Contributions for medical insurance of foreign employees';
				|tr = 'Yabancı işçilerin sağlık sigortası primleri'"; // @NStr-1
	ElsIf PredefinedItemName = "ContributionsForSocialInsuranceOfForeignEmployees" Then
		Return "vi = 'Phí bảo hiểm xã hội của lao động nước ngoài';
				|ru = 'Взносы на социальное страхование иностранных работников';
				|en = 'Contributions for social insurance of foreign employees';
				|it = 'Взносы на социальное страхование иностранных работников';
				|pl = 'Contributions for social insurance of foreign employees';
				|tr = 'Yabancı işçiler için sosyal sigorta primleri'"; // @NStr-1
	EndIf;
EndFunction
#EndRegion

#EndIf