///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Private

// Recipients types table broken down by storage and user presentation of these types.
//
// Returns: 
//   ValueTable - Table of recipient types.:
//       * MetadataObjectID - CatalogRef.MetadataObjectIDs - a reference that is stored
//                                                                                              in the database.
//       * RecipientsType  - TypeDescription - a type by which the recipient and exclusion list values are limited.
//       * Presentation   - String - a type presentation for users.
//       * MainCIKind   - CatalogRef.ContactInformationKinds - contact information kind: email, by
//                                                                       default.
//       * CIGroup        - CatalogRef.ContactInformationKinds - contact information kind group.
//       * ChoiceFormPath - String - a path to the choice form.
//
Function RecipientsTypesTable() Export
	
	TypesTable = New ValueTable;
	TypesTable.Columns.Add("MetadataObjectID", New TypeDescription("CatalogRef.MetadataObjectIDs"));
	TypesTable.Columns.Add("RecipientsType", New TypeDescription("TypeDescription"));
	TypesTable.Columns.Add("Presentation", New TypeDescription("String"));
	TypesTable.Columns.Add("MainCIKind", New TypeDescription("CatalogRef.ContactInformationKinds"));
	TypesTable.Columns.Add("CIGroup", New TypeDescription("CatalogRef.ContactInformationKinds"));
	TypesTable.Columns.Add("ChoiceFormPath", New TypeDescription("String"));
	TypesTable.Columns.Add("MainType", New TypeDescription("TypeDescription"));
	
	TypesTable.Indexes.Add("MetadataObjectID");
	TypesTable.Indexes.Add("RecipientsType");
	
	AvailableTypes = Metadata.Catalogs.ReportMailings.TabularSections.Recipients.Attributes.Recipient.Type.Types();
	
	// The Users catalog parameters + User groups.
	TypesSettings = New Structure;
	TypesSettings.Insert("MainType",       Type("CatalogRef.Users"));
	TypesSettings.Insert("AdditionalType", Type("CatalogRef.UserGroups"));
	ReportMailing.AddItemToRecipientsTypesTable(TypesTable, AvailableTypes, TypesSettings);
	
	// Extension mechanism.
	ReportMailingOverridable.OverrideRecipientsTypesTable(TypesTable, AvailableTypes);
	
	// Other catalogs parameters.
	BlankArray = New Array;
	For Each UnusedType In AvailableTypes Do
		ReportMailing.AddItemToRecipientsTypesTable(TypesTable, BlankArray, New Structure("MainType", UnusedType));
	EndDo;
	
	Return TypesTable;
EndFunction

// Reports to be excluded are used as a filter when selecting reports.
Function ReportsToExclude() Export
	
	MetadataArray = New Array;
	
	SSLSubsystemsIntegration.WhenDefiningExcludedReports(MetadataArray);
	ReportMailingOverridable.DetermineReportsToExclude(MetadataArray);
	
	Result = New Array;
	For Each ReportMetadata In MetadataArray Do
		Result.Add(Common.MetadataObjectID(ReportMetadata));
	EndDo;
	
	ReportsToExclude = New FixedArray(Result);
	
	Return ReportsToExclude;
	
EndFunction

Function FilesAndEmailTextParameters() Export

	ReportDistributionParameters = New Structure;
	
	ReportDistributionParameters.Insert("Recipient", NStr("vi = 'Người nhận';
															|ru = 'Получатель';
															|en = 'Recipient'; fa = 'گیرنده';
															|it = 'Получатель';
															|pl = 'Recipient';
															|tr = 'Alıcı'"));
	ReportDistributionParameters.Insert("ExecutionDate", NStr("vi = 'Ngày thực hiện';
																|ru = 'Дата выполнения';
																|en = 'Fulfillment date'; fa = 'تاریخ اجرا';
																|it = 'Data di scadenza';
																|pl = 'Data wykonania';
																|tr = 'Gerçekleştirme tarihi'"));
	ReportDistributionParameters.Insert("Author", NStr("vi = 'Tác giả';
														|ru = 'Автор';
														|en = 'Author'; fa = 'ایجادکننده';
														|it = 'Автор';
														|pl = 'Author';
														|tr = 'Oluşturan'"));
	ReportDistributionParameters.Insert("MailingDescription", NStr("vi = 'Tên gửi đi';
																	|ru = 'Наименование рассылки';
																	|en = 'Distribution description'; fa = 'شرح توزیع';
																	|it = 'Denominazione email massive';
																	|pl = 'Nazwa rozsyłki';
																	|tr = 'Bülten tanımı'"));
	ReportDistributionParameters.Insert("GeneratedReports", NStr("vi = 'Các báo cáo được lập';
																|ru = 'Сформированные отчеты';
																|en = 'Generated reports'; fa = 'گزارش‌های ایجادشده';
																|it = 'Creazione di report';
																|pl = 'Utworzone raporty';
																|tr = 'Oluşturulan raporlar'"));
	ReportDistributionParameters.Insert("SystemTitle", NStr("vi = 'Tiêu đề hệ thống';
															|ru = 'Заголовок системы';
															|en = 'Application title'; fa = 'عنوان برنامه';
															|it = 'Il titolo del sistema';
															|pl = 'Nagłówek systemu';
															|tr = 'Infobase başlığı'"));
	ReportDistributionParameters.Insert("DeliveryMethod", NStr("vi = 'Phương thức vận chuyển';
																|ru = 'Способ доставки';
																|en = 'Delivery method'; fa = 'روش تحویل';
																|it = 'Metodo di consegna';
																|pl = 'Sposób dostarczenia';
																|tr = 'Teslimat yöntemi'"));
	ReportDistributionParameters.Insert("ReportFormat", NStr("vi = 'Định dạng báo cáo';
															|ru = 'Формат отчета';
															|en = 'Report format'; fa = 'Report format';
															|it = 'Формат отчета';
															|pl = 'Report format';
															|tr = 'Rapor formatı'"));
	ReportDistributionParameters.Insert("Period", NStr("vi = 'Kỳ';
														|ru = 'Период';
														|en = 'Period'; fa = 'دوره';
														|it = 'Период';
														|pl = 'Period';
														|tr = 'Dönem'"));
	ReportDistributionParameters.Insert("MailingDate", NStr("vi = 'Ngày gửi';
															|ru = 'Дата рассылки';
															|en = 'Send date'; fa = 'تاریخ ارسال';
															|it = 'Data email massive';
															|pl = 'Data rozsyłki';
															|tr = 'Bülten tarihi'"));
	ReportDistributionParameters.Insert("ReportDescription1", NStr("vi = 'Tên báo cáo';
																	|ru = 'Наименование отчета';
																	|en = 'Report name'; fa = 'نام گزارش';
																	|it = 'Наименование отчета';
																	|pl = 'Report name';
																	|tr = 'Rapor tanımı'"));
	
	Return ReportDistributionParameters;

EndFunction

#EndRegion
