///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	MetadataObject = Common.MetadataObjectByFullName(Parameters.FullObjectName);
	
	If Common.IsConstant(MetadataObject) Then
		ObjectTypePresentation = NStr("vi = 'hằng';
										|ru = 'константе';
										|en = 'constant'; fa = 'constant';
										|it = 'costante';
										|pl = 'stałej';
										|tr = 'sabite'");
	ElsIf Common.IsCatalog(MetadataObject) Then
		ObjectTypePresentation = NStr("vi = 'danh mục';
										|ru = 'справочнику';
										|en = 'catalog'; fa = 'catalog';
										|it = 'directory';
										|pl = 'katalogowi';
										|tr = 'kataloga'");
	ElsIf Common.IsDocument(MetadataObject) Then
		ObjectTypePresentation = NStr("vi = 'chứng từ';
										|ru = 'документу';
										|en = 'document'; fa = 'document';
										|it = 'documento';
										|pl = 'dokumentowi';
										|tr = 'belgeye'");
	ElsIf ODataInterfaceInternal.IsSequenceRecordSet(MetadataObject) Then
		ObjectTypePresentation = NStr("vi = 'chuỗi nối tiếp';
										|ru = 'последовательности';
										|en = 'sequence'; fa = 'sequence';
										|it = 'sequenze';
										|pl = 'kolejności';
										|tr = 'sıraya'");
	ElsIf Common.IsDocumentJournal(MetadataObject) Then
		ObjectTypePresentation = NStr("vi = 'nhật ký chứng từ';
										|ru = 'журналу документов';
										|en = 'document journal'; fa = 'document journal';
										|it = 'registro documenti';
										|pl = 'dziennikowi dokumentów';
										|tr = 'belgeler günlüğüne'");
	ElsIf Common.IsEnum(MetadataObject) Then
		ObjectTypePresentation = NStr("vi = 'liệt kê';
										|ru = 'перечислению';
										|en = 'enumeration'; fa = 'enumeration';
										|it = 'enumerazione';
										|pl = 'naliczaniu';
										|tr = 'transfere'");
	ElsIf Common.IsChartOfCharacteristicTypes(MetadataObject) Then
		ObjectTypePresentation = NStr("vi = 'hệ thống dạng đặc tính';
										|ru = 'плану видов характеристик';
										|en = 'chart of characteristic types'; fa = 'chart of characteristic types';
										|it = 'piano dei tipi di caratteristiche';
										|pl = 'planowi rodzajów charakterystyk';
										|tr = 'özellik türleri planına'");
	ElsIf Common.IsChartOfAccounts(MetadataObject) Then
		ObjectTypePresentation = NStr("vi = 'hệ thống tài khoản';
										|ru = 'плану счетов';
										|en = 'chart of accounts'; fa = 'chart of accounts';
										|it = 'piani dei conti';
										|pl = 'planowi kont';
										|tr = 'hesap planına'");
	ElsIf Common.IsChartOfCalculationTypes(MetadataObject) Then
		ObjectTypePresentation = NStr("vi = 'hệ thống dạng tính toán';
										|ru = 'плану видов расчета';
										|en = 'chart of calculation types'; fa = 'chart of calculation types';
										|it = 'piani dei tipi di calcolo';
										|pl = 'planowi rodzajów rozliczeń';
										|tr = 'hesaplama türleri çizelgesine'");
	ElsIf Common.IsInformationRegister(MetadataObject) Then
		ObjectTypePresentation = NStr("vi = 'biểu ghi thông tin';
										|ru = 'регистру сведений';
										|en = 'information register'; fa = 'information register';
										|it = 'registri delle informazioni';
										|pl = 'rejestrowi informacji';
										|tr = 'bilgi kaydına'");
	ElsIf Common.IsAccumulationRegister(MetadataObject) Then
		ObjectTypePresentation = NStr("vi = 'biểu ghi tích lũy';
										|ru = 'регистру накопления';
										|en = 'accumulation register'; fa = 'accumulation register';
										|it = 'registri di accumulo';
										|pl = 'rejestrowi akumulacji';
										|tr = 'birikim kaydına'");
	ElsIf Common.IsAccountingRegister(MetadataObject) Then
		ObjectTypePresentation = NStr("vi = 'biểu ghi kế toán';
										|ru = 'регистру бухгалтерии';
										|en = 'accounting register'; fa = 'accounting register';
										|it = 'registro contabilità';
										|pl = 'rejestrowi księgowości';
										|tr = 'muhasebe kaydına'");
	ElsIf Common.IsCalculationRegister(MetadataObject) Then
		ObjectTypePresentation = NStr("vi = 'biểu ghi tính toán';
										|ru = 'регистру расчета';
										|en = 'calculation register'; fa = 'calculation register';
										|it = 'registro di calcolo';
										|pl = 'rejestrowi rozliczeń';
										|tr = 'hesaplama kaydına'");
	ElsIf ODataInterfaceInternal.IsRecalculationRecordSet(MetadataObject) Then
		ObjectTypePresentation = NStr("vi = 'tính lại';
										|ru = 'перерасчету';
										|en = 'recalculation'; fa = 'recalculation';
										|it = 'ricalcolo';
										|pl = 'przeliczeniu';
										|tr = 'yeniden hesaplamaya'");
	ElsIf Common.IsBusinessProcess(MetadataObject) Then
		ObjectTypePresentation = NStr("vi = 'quy trình nghiệp vụ';
										|ru = 'бизнес-процессу';
										|en = 'business process'; fa = 'business process';
										|it = 'processo aziendale';
										|pl = 'procesowi biznesowemu';
										|tr = 'iş sürecine'");
	ElsIf Common.IsTask(MetadataObject) Then
		ObjectTypePresentation = NStr("vi = 'nhiệm vụ';
										|ru = 'задаче';
										|en = 'task'; fa = 'task';
										|it = 'compito';
										|pl = 'zadaniu';
										|tr = 'göreve'");
	ElsIf Common.IsExchangePlan(MetadataObject) Then
		ObjectTypePresentation = NStr("vi = 'sơ đồ trao đổi';
										|ru = 'плану обмена';
										|en = 'exchange plan'; fa = 'exchange plan';
										|it = 'piano di scambio';
										|pl = 'planowi wymiany';
										|tr = 'değişim planına'");
	EndIf;
	
	If Parameters.Create Then
		
		Items.GroupPageHeader.CurrentPage = Items.PageHeaderAddGroup;
		Items.PagesFooterGroup.CurrentPage = Items.PageFooterAddGroup;
		Items.TitleHeaderAddDecoration.Title = StringFunctionsClientServer.SubstituteParametersToString(
			Items.TitleHeaderAddDecoration.Title,
			ObjectTypePresentation,
			MetadataObject.Presentation());
		
	Else
		
		Items.GroupPageHeader.CurrentPage = Items.PageHeaderDeletionGroup;
		Items.PagesFooterGroup.CurrentPage = Items.PageFooterDeleteGroup;
		Items.TitleHeaderDeletionDecoration.Title = StringFunctionsClientServer.SubstituteParametersToString(
			Items.TitleHeaderDeletionDecoration.Title,
			ObjectTypePresentation,
			MetadataObject.Presentation());
		
	EndIf;
	
	Title = StringFunctionsClientServer.SubstituteParametersToString(
		Title, MetadataObject.Presentation());
	
	// Populate tree.
	
	Tree = New ValueTree();
	
	Tree.Columns.Add("FullName", New TypeDescription("String"));
	Tree.Columns.Add("Presentation", New TypeDescription("String"));
	Tree.Columns.Add("Class", New TypeDescription("Number", , New NumberQualifiers(10, 0, AllowedSign.Nonnegative)));
	Tree.Columns.Add("Picture", New TypeDescription("Picture"));
	
	AddTreeRootRow(Tree, "Constant", NStr("vi = 'Hằng';
											|ru = 'Константы';
											|en = 'Constants'; fa = 'ثابت‌ها';
											|it = 'Costanti';
											|pl = 'Constants';
											|tr = 'Sabitler'"), 1, PictureLib.Constant);
	AddTreeRootRow(Tree, "Catalog", NStr("vi = 'Danh mục';
										|ru = 'Справочники';
										|en = 'Catalogs'; fa = 'فهرست‌ها';
										|it = 'Directory';
										|pl = 'Kartoteki';
										|tr = 'Kataloglar'"), 2, PictureLib.Catalog);
	AddTreeRootRow(Tree, "Document", NStr("vi = 'Chứng từ';
											|ru = 'Документы';
											|en = 'Documents'; fa = 'اسناد';
											|it = 'Documenti';
											|pl = 'Documents';
											|tr = 'Belgeler'"), 3, PictureLib.Document);
	AddTreeRootRow(Tree, "DocumentJournal", NStr("vi = 'Nhật ký chứng từ';
												|ru = 'Журналы документов';
												|en = 'Document journals'; fa = 'Document journals';
												|it = 'Registri dei documenti';
												|pl = 'Dzienniki dokumentów';
												|tr = 'Belge günlükleri'"), 4, PictureLib.DocumentJournal);
	AddTreeRootRow(Tree, "Enum", NStr("vi = 'Liệt kê';
										|ru = 'Перечисление';
										|en = 'Enumeration'; fa = 'Enumeration';
										|it = 'Enumerazione';
										|pl = 'Enumeration';
										|tr = 'Transfer'"), 5, PictureLib.Enum);
	AddTreeRootRow(Tree, "ChartOfCharacteristicTypes", NStr("vi = 'Hệ thống dạng đặc tính';
															|ru = 'Планы видов характеристик';
															|en = 'Charts of characteristic types'; fa = 'Charts of characteristic types';
															|it = 'Piani dei tipi di caratteristiche';
															|pl = 'Plany rodzajów charakterystyk';
															|tr = 'Özellik türü listeleri'"), 6, PictureLib.ChartOfCharacteristicTypes);
	AddTreeRootRow(Tree, "ChartOfAccounts", NStr("vi = 'Hệ thống tài khoản';
												|ru = 'Планы счетов';
												|en = 'Charts of accounts'; fa = 'سرفصل‌های حساب';
												|it = 'Piani dei conti';
												|pl = 'Plany rachunków';
												|tr = 'Hesap planları'"), 7, PictureLib.ChartOfAccounts);
	AddTreeRootRow(Tree, "ChartOfCalculationTypes", NStr("vi = 'Hệ thống dạng tính toán';
														|ru = 'Планы видов расчета';
														|en = 'Charts of calculation types'; fa = 'Charts of calculation types';
														|it = 'Piani dei tipi di calcolo';
														|pl = 'Plany rodzajów obliczeń';
														|tr = 'Hesaplama türü planları'"), 8, PictureLib.ChartOfCalculationTypes);
	AddTreeRootRow(Tree, "InformationRegister", NStr("vi = 'Biểu ghi thông tin';
													|ru = 'Регистры сведений';
													|en = 'Information registers'; fa = 'ثبت‌های اطلاعاتی';
													|it = 'Registri delle informazioni';
													|pl = 'Rejestry informacji';
													|tr = 'Bilgi kayıtları'"), 9, PictureLib.InformationRegister);
	AddTreeRootRow(Tree, "AccumulationRegister", NStr("vi = 'Biểu ghi tích lũy';
														|ru = 'Регистры накопления';
														|en = 'Accumulation registers'; fa = 'ثبت‌های انباشتی';
														|it = 'Registri di accumulo';
														|pl = 'Rejestry kumulacji';
														|tr = 'Birikim kayıtları'"), 10, PictureLib.AccumulationRegister);
	AddTreeRootRow(Tree, "AccountingRegister", NStr("vi = 'Biểu ghi kế toán';
													|ru = 'Регистры бухгалтерии';
													|en = 'Accounting registers'; fa = 'Accounting registers';
													|it = 'Registri contabilità';
													|pl = 'Rejestry księgowości';
													|tr = 'Muhasebe kayıtları'"), 11, PictureLib.AccountingRegister);
	AddTreeRootRow(Tree, "CalculationRegister", NStr("vi = 'Biểu ghi tính toán';
													|ru = 'Регистры расчета';
													|en = 'Calculation registers'; fa = 'Calculation registers';
													|it = 'Registri di calcolo';
													|pl = 'Rejestry rozliczenia';
													|tr = 'Mutabakat işlemleri kayıtları'"), 12, PictureLib.CalculationRegister);
	AddTreeRootRow(Tree, "BusinessProcess", NStr("vi = 'Quy trình nghiệp vụ';
												|ru = 'Бизнес-процессы';
												|en = 'Business processes'; fa = 'فرایندهای تجاری';
												|it = 'Processi aziendali';
												|pl = 'Business processes';
												|tr = 'İş süreçleri'"), 13, PictureLib.BusinessProcess);
	AddTreeRootRow(Tree, "Task", NStr("vi = 'Nhiệm vụ';
										|ru = 'Задачи';
										|en = 'Tasks'; fa = 'وظایف';
										|it = 'Obiettivi';
										|pl = 'Tasks';
										|tr = 'Görevler'"), 14, PictureLib.Task);
	AddTreeRootRow(Tree, "ExchangePlan", NStr("vi = 'Sơ đồ trao đổi';
												|ru = 'Планы обмена';
												|en = 'Exchange plans'; fa = 'Exchange plans';
												|it = 'Piani di scambio';
												|pl = 'Plany wymiany';
												|tr = 'Değiştirme planları'"), 15, PictureLib.ExchangePlan);
	
	For Each Dependence In Parameters.ObjectDependencies Do
		AddNestedTreeRow(Tree, Common.MetadataObjectByFullName(Dependence));
	EndDo;
	
	Tree.Columns.Delete(Tree.Columns["FullName"]);
	Tree.Columns.Delete(Tree.Columns["Class"]);
	
	LinesToDelete = New Array();
	For Each TreeRow In Tree.Rows Do
		If TreeRow.Rows.Count() = 0 Then
			LinesToDelete.Add(TreeRow);
		Else
			TreeRow.Rows.Sort("Presentation");
		EndIf;
	EndDo;
	For Each RowToDelete In LinesToDelete Do
		Tree.Rows.Delete(RowToDelete);
	EndDo;
	
	ValueToFormAttribute(Tree, "MetadataObjects");
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure AddTreeRootRow(Tree,Val FullName, Val Presentation, Val Class, Val Picture)
	
	NewRow = Tree.Rows.Add();
	NewRow.FullName = FullName;
	NewRow.Presentation = Presentation;
	NewRow.Class = Class;
	NewRow.Picture = Picture;
	
EndProcedure

&AtServer
Procedure AddNestedTreeRow(Tree, Val MetadataObject)
	
	FullName = MetadataObject.FullName();
	
	NameStructure = StrSplit(FullName, ".");
	ObjectClass = NameStructure[0];
	
	RowOwner = Undefined;
	For Each TreeRow In Tree.Rows Do
		If TreeRow.FullName = ObjectClass Then
			RowOwner = TreeRow;
			Break;
		EndIf;
	EndDo;
	
	If RowOwner = Undefined Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đối tượng metadata chưa xác định: %1';
				|ru = 'Неизвестный объект метаданных: %1';
				|en = 'Unknown metadata object: %1'; fa = 'Unknown metadata object: %1';
				|it = 'Oggetto di metadati sconosciuto: %1';
				|pl = 'Nieznany obiekt metadanych: %1';
				|tr = 'Bilinmeyen meta veri nesnesi:%1'"), FullName);
	EndIf;
	
	NewRow = RowOwner.Rows.Add();
	
	NewRow.Presentation = MetadataObject.Presentation();
	NewRow.Class = RowOwner.Class;
	NewRow.Picture = RowOwner.Picture;
	
EndProcedure

#EndRegion