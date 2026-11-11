///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Allows you to change interface upon embedding.
//
// Parameters:
//  InterfaceSettings5 - Structure:
//   * UseExternalUsers - Boolean - initial value is False
//     if you set to True, period-end closing dates can be set up for external users.
//
Procedure InterfaceSetup(InterfaceSettings5) Export
	
	PeriodEndClosingDatesTM.InterfaceSetup(InterfaceSettings5);
	PeriodClosingDatesLocalization.InterfaceSetup(InterfaceSettings5);
	
EndProcedure

// Fills in sections of period-end closing dates used upon their setup.
// If you do not specify any section, then only common period-end closing date setup will be available.
//
// Parameters:
//  Sections - ValueTable:
//   * Name - String - Name used in the data source details
//       in the FillDataSourcesForPeriodClosingCheck procedure.
//
//   * Id - UUID - an item reference ID of chart of characteristic types.
//       To get an ID, execute the platform method in 1C:Enterprise mode:
//       "ChartsOfCharacteristicTypes.PeriodClosingDatesSections.GetRef().UUID()".
//       Do not specify IDs received using any other method
//       as it can violate their uniqueness.
//
//   * Presentation - String - presents a section in the form of period-end closing date setup.
//
//   * ObjectsTypes  - Array - object reference types, by which you can set period-end closing dates,
//       for example, Type("CatalogRef.Companies"), if no type is specified,
//       period-end closing dates are set up only to the precision of a section.
//
Procedure OnFillPeriodClosingDatesSections(Sections) Export
	
	Section = Sections.Add();
	Section.Name  = "ExpenseReports";
	Section.Id = New UUID("199db5e2-c45a-4004-9e87-742579e7a749");
	Section.Presentation = NStr("vi = 'Giấy thanh toán tiền tạm ứng';
								|ru = 'Авансовые отчеты';
								|en = 'Expense reports'; fa = 'گزارش‌های هزینه';
								|it = 'Note spese';
								|pl = 'Raporty zaliczkowe';
								|tr = 'Gider raporları'");
	Section.ObjectsTypes.Add(Type("CatalogRef.Companies"));

	Section = Sections.Add();
	Section.Name  = "Bank";
	Section.Id = New UUID("0f558de9-37af-484b-8f46-1ba523cf01d2");
	Section.Presentation = NStr("vi = 'Ngân hàng';
								|ru = 'Банк';
								|en = 'Bank'; fa = 'بانک';
								|it = 'Banca';
								|pl = 'Bank';
								|tr = 'Banka'");
	Section.ObjectsTypes.Add(Type("CatalogRef.CompaniesBankAccounts"));

	Section = Sections.Add();
	Section.Name  = "Bookkeeping";
	Section.Id = New UUID("2bdf6479-8eaf-4ec0-93a1-412e8659a178");
	Section.Presentation = NStr("vi = 'Kế toán';
								|ru = 'Бухгалтерский учет';
								|en = 'Local accounting'; fa = 'حسابداری محلی';
								|it = 'Contabilità';
								|pl = 'Księgowość';
								|tr = 'Muhasebe'");
	Section.ObjectsTypes.Add(Type("CatalogRef.Companies"));
	Section = Sections.Add();
	Section.Name  = "Budgeting";
	Section.Id = New UUID("10b010bf-ff02-407a-b71d-fa3d2c8186cc");
	Section.Presentation = NStr("vi = 'Quản lý ngân sách';
								|ru = 'Бюджетирование';
								|en = 'Budgeting'; fa = 'بودجه‌بندی';
								|it = 'Budgeting';
								|pl = 'Budgeting';
								|tr = 'Bütçeleme'");
	Section.ObjectsTypes.Add(Type("CatalogRef.BudgetingScenarios"));
	Section = Sections.Add();
	Section.Name  = "OBEntry";
	Section.Id = New UUID("c061d639-5929-11ea-87c6-1831bf523f36");
	Section.Presentation = NStr("vi = 'Nhập số dư đầu kỳ';
								|ru = 'Ввод остатков';
								|en = 'Balance entry'; fa = 'ورود مانده';
								|it = 'Inserimento dei saldi';
								|pl = 'Wpisanie zapasów';
								|tr = 'Bakiyeyi gir'");
	Section.ObjectsTypes.Add(Type("CatalogRef.Companies"));
	Section = Sections.Add();
	Section.Name  = "NonCurrentAssets";
	Section.Id = New UUID("1dc4b831-3ca1-11e7-9d6b-e0cb4ed5f5dc");
	Section.Presentation = NStr("vi = 'Tài sản dài hạn';
								|ru = 'Внеоборотные активы';
								|en = 'Fixed and intangible assets'; fa = 'دارایی‌های ثابت و نامشهود';
								|it = 'Attivi non circolanti';
								|pl = 'Środki trwałe';
								|tr = 'Duran varlıklar'");
	Section.ObjectsTypes.Add(Type("CatalogRef.Companies"));
	Section = Sections.Add();
	Section.Name  = "InternalInventoryTransfers";
	Section.Id = New UUID("a7c88ae7-129c-45c5-bdcd-df587700fa2d");
	Section.Presentation = NStr("vi = 'Điều chuyển hàng hóa nội bộ';
								|ru = 'Внутреннее товародвижение';
								|en = 'Internal inventory transfers'; fa = 'انتقالات داخلی موجودی';
								|it = 'Flusso di prodotti interno';
								|pl = 'Wewnętrzny ruch towarów';
								|tr = 'Dahili stok transferleri'");
	Section.ObjectsTypes.Add(Type("CatalogRef.Companies"));

	Section = Sections.Add();
	Section.Name  = "Purchases";
	Section.Id = New UUID("fc4596d4-f365-4986-b633-fe77017b938f");
	Section.Presentation = NStr("vi = 'Mua hàng';
								|ru = 'Закупки';
								|en = 'Purchases'; fa = 'خریدها';
								|it = 'Acquisti';
								|pl = 'Purchases';
								|tr = 'Satın alma'");
	Section.ObjectsTypes.Add(Type("CatalogRef.Companies"));

	Section = Sections.Add();
	Section.Name  = "CashAccount";
	Section.Id = New UUID("97e0cfbc-3a80-40d5-bbce-ce9c3e87e7d8");
	Section.Presentation = NStr("vi = 'Quỹ tiền mặt';
								|ru = 'Касса';
								|en = 'Cash account'; fa = 'صندوق';
								|it = 'Cassa';
								|pl = 'Cash account';
								|tr = 'Kasa hesabı'");
	Section.ObjectsTypes.Add(Type("CatalogRef.CashAccounts"));
	Section = Sections.Add();
	Section.Name  = "FinancialAccounting";
	Section.Id = New UUID("759a6987-ef82-442c-a4eb-2735afaa10d2");
	Section.Presentation = NStr("vi = 'Kế toán quốc tế';
								|ru = 'Международный учет';
								|en = 'Financial accounting'; fa = 'حسابداری مالی';
								|it = 'Contabilità internazionale';
								|pl = 'Rachunkowość międzynarodowa';
								|tr = 'Uluslararası muhasebe'");
	Section.ObjectsTypes.Add(Type("CatalogRef.Companies"));//

	Section = Sections.Add();
	Section.Name  = "Planning";
	Section.Id = New UUID("0c370df6-fb93-499d-bec3-81c4b7dcfcf2");
	Section.Presentation = NStr("vi = 'Lập kế hoạch';
								|ru = 'Планирование';
								|en = 'Planning'; fa = 'برنامه‌ریزی';
								|it = 'Pianificazione';
								|pl = 'Planning';
								|tr = 'Planlama'");
	Section.ObjectsTypes.Add(Type("CatalogRef.SalesOperationsPlanningScenarios"));

	Section = Sections.Add();
	Section.Name  = "Sales";
	Section.Id = New UUID("f9d6852a-09c2-4505-901e-ac07fa0a73eb");
	Section.Presentation = NStr("vi = 'Bán hàng';
								|ru = 'Продажи';
								|en = 'Sales'; fa = 'فروش';
								|it = 'Vendite';
								|pl = 'Sprzedaż';
								|tr = 'Satış'");
	Section.ObjectsTypes.Add(Type("CatalogRef.Companies"));

	Section = Sections.Add();
	Section.Name  = "IntercompanySales";
	Section.Id = New UUID("c061d63b-5929-11ea-87c6-1831bf523f36");
	Section.Presentation = NStr("vi = 'Bán hàng giữa các doanh nghiệp';
								|ru = 'Продажи между организациями';
								|en = 'Intercompany sales'; fa = 'فروش بین‌شرکتی';
								|it = 'Vendite tra le organizzazioni';
								|pl = 'Sprzedaże między firmami';
								|tr = 'İş yerleri arası satışlar'");
	Section.ObjectsTypes.Add(Type("CatalogRef.Companies"));

	Section = Sections.Add();
	Section.Name  = "Production";
	Section.Id = New UUID("8795bd29-84ab-47b5-a59f-4fff6b242bab");
	Section.Presentation = NStr("vi = 'Sản xuất';
								|ru = 'Производство';
								|en = 'Production'; fa = 'تولید';
								|it = 'Produzione';
								|pl = 'Production';
								|tr = 'Üretim'");
	Section.ObjectsTypes.Add(Type("CatalogRef.Companies"));

	Section = Sections.Add();
	Section.Name  = "RoutineOperations";
	Section.Id = New UUID("49fca300-0137-4f5e-bc8d-af6cc30545a3");
	Section.Presentation = NStr("vi = 'Giao dịch thường kỳ';
								|ru = 'Регламентные операции';
								|en = 'Scheduled jobs'; fa = 'کارهای زمان‌بندی‌شده';
								|it = 'Operazioni regolamentate';
								|pl = 'Operacje reglamentowane';
								|tr = 'Planlanmış İşlemler'");
	Section.ObjectsTypes.Add(Type("CatalogRef.Companies"));
	
	Section = Sections.Add();
	Section.Name  = "RetailSales";
	Section.Id = New UUID("c061d646-5929-11ea-87c6-1831bf523f36");
	Section.Presentation = NStr("vi = 'Bán lẻ';
								|ru = 'Розничные продажи';
								|en = 'Retail sales'; fa = 'فروش خرده‌فروشی';
								|it = 'Vendite al dettaglio';
								|pl = 'Sprzedaże detaliczne';
								|tr = 'Perakende satışlar'");
	Section.ObjectsTypes.Add(Type("CatalogRef.Companies"));
	
	Section = Sections.Add();
	Section.Name  = "DebtReconciliationsAndAdjustments";
	Section.Id = New UUID("ece392ee-5209-4bfa-9f32-5b1244b1f74e");
	Section.Presentation = NStr("vi = 'Điều chỉnh và đối chiếu công nợ';
								|ru = 'Сверки и корректировки задолженности';
								|en = 'Debt reconciliations and adjustments'; fa = 'Debt reconciliations and adjustments';
								|it = 'Verifiche e correzioni di debiti';
								|pl = 'Weryfikacje i korekty zadłużenia';
								|tr = 'Borç mutabakatları ve düzeltmeleri'");
	Section.ObjectsTypes.Add(Type("CatalogRef.Companies"));

	Section = Sections.Add();
	Section.Name  = "WarehouseTransactions";
	Section.Id = New UUID("f37d661e-6540-4890-8642-f7481ff1ee7b");
	Section.Presentation = NStr("ru = 'Складские операции (на ордерных складах), доставка';
								|vi = 'Warehouse operations — Warehouse Management, delivery';
								|en = 'Warehouse operations — Warehouse Management, delivery'; fa = 'Warehouse operations — Warehouse Management, delivery';
								|it = 'Warehouse operations — Warehouse Management, delivery';
								|pl = 'Warehouse operations — Warehouse Management, delivery';
								|tr = 'Ambar işlemleri (sipariş ambarlarında), teslimat'");
	Section.ObjectsTypes.Add(Type("CatalogRef.Warehouses"));
	
	Section = Sections.Add();
	Section.Name  = "FinancialOutline";
	Section.Id = New UUID("66a40e05-5ebd-11ea-87c6-1831bf523f36");
	Section.Presentation = NStr("vi = 'Dịch vụ tài chính';
								|ru = 'Финансовый контур';
								|en = 'Financial contour'; fa = 'Financial contour';
								|it = 'Contorno finanziario';
								|pl = 'Kontur finansowy';
								|tr = 'Mali taslak'");
	Section.ObjectsTypes.Add(Type("CatalogRef.Companies"));
	
	Section = Sections.Add();
	Section.Name  = "CustomerRebates";
	Section.Id = New UUID("2974da80-1b5e-4d98-8a14-9cb26b560892");
	Section.Presentation = NStr("vi = 'Thưởng lũy kế cho khách hàng';
								|ru = 'Ретро-бонусы клиентов';
								|en = 'Customer rebates'; fa = 'تخفیف‌های حجمی مشتری';
								|it = 'Ретро-бонусы клиентов';
								|pl = 'Customer rebates';
								|tr = 'Müşteri primleri'");
	Section.ObjectsTypes.Add(Type("CatalogRef.Companies"));
	
	Section = Sections.Add();
	Section.Name  = "VendorRebates";
	Section.Id = New UUID("9a629851-6440-11ef-8435-005056be3dc8");
	Section.Presentation = NStr("vi = 'Thưởng lũy kế của nhà cung cấp';
								|ru = 'Ретро-бонусы поставщиков';
								|en = 'Vendor rebates'; fa = 'تخفیف‌های برگشتی تأمین‌کننده';
								|it = 'Ретро-бонусы поставщиков';
								|pl = 'Vendor rebates';
								|tr = 'Tedarikçi retro bonusları'");
	Section.ObjectsTypes.Add(Type("CatalogRef.Companies"));
	Section = Sections.Add();
	Section.Name  = "RMManagement";
	Section.Id = New UUID("4fbd7445-50f5-4aa4-ac19-be884591f1b6");
	Section.Presentation = NStr("vi = 'Quản lý sửa chữa';
								|ru = 'Управление ремонтами';
								|en = 'R&&M management'; fa = 'مدیریت تعمیر و نگهداری';
								|it = 'Gestione delle riparazioni';
								|pl = 'Zarządzanie remontami';
								|tr = 'Bakım-onarım yönetimi'");
	Section.ObjectsTypes.Add(Type("CatalogRef.Companies"));
	PeriodClosingDatesLocalization.OnFillPeriodClosingDatesSections(Sections);

EndProcedure

// Allows you to specify tables and object fields to check period-end closing.
// To add a new source to DataSources  See PeriodClosingDates.AddRow.
//
// Called from the ChangeProhibited procedure of the PeriodEndClosingDates common module
// used in the BeforeWrite event subscription of the object to check for period-end
// closing and canceled restricted object changes.
//
// Parameters:
//  DataSources - ValueTable:
//   * Table     - String - a full name of a metadata object,
//                   for example, Metadata.Documents.PurchaseInvoice.FullName().
//   * DateField    - String - an attribute name of an object or a tabular section,
//                   for example: "Date", "Goods.ShipmentDate".
//   * Section      - String - Name of a period-end closing date section
//                   specified in the OnFillPeriodClosingDatesSections procedure (see above).
//   * ObjectField - String - an attribute name of an object or a tabular section,
//                   for example: "Company", "Goods.Warehouse".
//
Procedure FillDataSourcesForPeriodClosingCheck(DataSources) Export
	
	PeriodEndClosingDatesTM.FillDataSourcesForPeriodClosingCheck(DataSources);
	PeriodClosingDatesLocalization.FillDataSourcesForPeriodClosingCheck(DataSources);
	
	
EndProcedure

// "Allows overriding the execution of the change restriction check in an arbitrary way.
//
// If the check is performed during the document write process, the "AdditionalProperties" of
// the document "Object" includes the "WriteMode" ("DocumentWriteMode") property.
// If the check is performed on a record set, the "AdditionalProperties" of the record set "Object" contains the "Replacing" property ("Boolean, ReplacementMode).
// In the case of record replacement, the Filter property is configured to retrieve existing records from the database.
// 
//  
// Parameters:
//  Object       - CatalogObject
//               - DocumentObject
//               - ChartOfCharacteristicTypesObject
//               - ChartOfAccountsObject
//               - ChartOfCalculationTypesObject
//               - BusinessProcessObject
//               - TaskObject
//               - ExchangePlanObject
//               - InformationRegisterRecordSet
//               - AccumulationRegisterRecordSet
//               - AccountingRegisterRecordSet
//               - CalculationRegisterRecordSet - The data item or record set to be checked
//                 (as in the handlers "BeforeWrite" and "OnReadAtServer").
//
//  PeriodClosingCheck    - Boolean - set to False to skip period-end closing check.
//  ImportRestrictionCheckNode - ExchangePlanRef
//                              - Undefined - set to Undefined 
//                                to skip data import restriction check.
//  ObjectVersion               - String - Set "OldVersion" or "NewVersion" to check only the old
//                                object version (in the database) or only the new object version
//                                (in the "Object" parameter).
//                                By default, it is set to "" (both object versions are checked at the same time).
//
Procedure BeforeCheckPeriodClosing(Object,
                                         PeriodClosingCheck,
                                         ImportRestrictionCheckNode,
                                         ObjectVersion) Export
	
	PeriodEndClosingDatesTM.BeforeCheckPeriodClosing(
		Object,
		PeriodClosingCheck,
		ImportRestrictionCheckNode,
		ObjectVersion);
		
	PeriodClosingDatesLocalization.BeforeCheckPeriodClosing(
		Object,
		PeriodClosingCheck,
		ImportRestrictionCheckNode,
		ObjectVersion);
	
EndProcedure

// Allows overriding the process of retrieving data for checking the date restriction of an old (existing) data version.
// If "DataToCheck" is provided, it will not be automatically loaded from the database based on the "MetadataObject" and "DataID" parameters.
// If the check is conducted on a record set, the "AdditionalProperties" of the record set "DataID" contains the
//
// "Replacing" property (Boolean, SubstitutionMode) with possible values:
// "Replacing", "RefreshEnabled", "Join" and "Delete".
// In the case of record replacement, the "Filter" property is configured to retrieve existing records from the database.
// 
//
// Parameters:
//  MetadataObject - MetadataObject - a metadata object of data to be received.
//  DataID - CatalogRef
//                      - DocumentRef
//                      - ChartOfCharacteristicTypesRef
//                      - ChartOfAccountsRef
//                      - ChartOfCalculationTypesRef
//                      - BusinessProcessRef
//                      - TaskRef
//                      - ExchangePlanRef - Reference to the data item.
//                      - Filter - Record set filter in case "Replacing" is set to "True".
//                      - InformationRegisterRecordSet
//                      - AccumulationRegisterRecordSet
//                      - AccountingRegisterRecordSet
//                      - CalculationRegisterRecordSet - Record set in case "Replacing" in not Boolean.
//
//  ImportRestrictionCheckNode - Undefined
//                              - ExchangePlanRef - if Undefined, check period-end closing; 
//                                otherwise check data import from the exchange plan node.
//
//  DataToCheck - See PeriodClosingDates.DataToCheckTemplate.
//
//  Example:
//  If TypeOf(DataID) = Type("DocumentRef.Order") Then
//  	Data = Common.ObjectAttributesValues(DataID, "Company, WorkEndDate, WorkOrder");
//  	If Data.WorkOrder Then
//  		Check = DataToCheck.Add();
//  		Check.Section = "WorkOrders";
//  		Check.Object = Data.Company;
//  		Check.Date = Data.WorkEndDate;
//  	EndIf;
//  EndIf;
//
Procedure BeforeCheckOldDataVersion(MetadataObject, DataID, ImportRestrictionCheckNode, DataToCheck) Export
	
	PeriodEndClosingDatesTM.BeforeCheckOldDataVersion(MetadataObject, DataID, ImportRestrictionCheckNode, DataToCheck);
	
EndProcedure

// Allows overriding the process of retrieving data for checking the date restriction of a new (future) data version.
// If "DataToCheck" is provided, it will not be automatically extracted from the object or additionally loaded from
// the database based on the "MetadataObject" and "Data" parameters. If the check is performed during the document write process,
//
// the "AdditionalProperties" of the document "Data" includes the "WriteMode" ("DocumentWriteMode") property.
// If the check is conducted on a record set, the "AdditionalProperties" of the record set "Data" contains the
// "Replacing" property (Boolean, SubstitutionMode) with possible values:
// "Add", "Replacing", "RefreshEnabled", "Join".
// In the case of record replacement, the "Filter" property is configured to retrieve existing records from the database.
// 
//
// Parameters:
//  MetadataObject - MetadataObject - a metadata object of data to be received.
//  Data  - CatalogObject
//          - DocumentObject
//          - ChartOfCharacteristicTypesObject
//          - ChartOfAccountsObject
//          - ChartOfCalculationTypesObject
//          - BusinessProcessObject
//          - TaskObject
//          - ExchangePlanObject
//          - InformationRegisterRecordSet
//          - AccumulationRegisterRecordSet
//          - AccountingRegisterRecordSet
//          - CalculationRegisterRecordSet - Data item or record set to be checked.
//
//  ImportRestrictionCheckNode - Undefined
//                              - ExchangePlanRef - if Undefined, check period-end closing; 
//                                otherwise check data import from the exchange plan node.
//
//  DataToCheck - See PeriodClosingDates.DataToCheckTemplate.
//
//  Example:
//  If TypeOf(Data) = Type("DocumentObject.Order") AND Data.WorkOrder Then
//  	
//  	Check = DataToCheck.Add();
//  	Check.Section = "WorkOrders";
//  	Check.Object = Data.Company;
//  	Check.Date = Data.WorkEndDate;
//  	
//  EndIf;
//
Procedure BeforeCheckNewDataVersion(MetadataObject, Data, ImportRestrictionCheckNode, DataToCheck) Export

	PeriodEndClosingDatesTM.BeforeCheckNewDataVersion(MetadataObject, Data, ImportRestrictionCheckNode, DataToCheck);
	
EndProcedure

#EndRegion
