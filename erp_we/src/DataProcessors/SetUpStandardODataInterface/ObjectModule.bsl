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

Var ObjectsTree;
Var AdditionDependencies;
Var DeletionDependencies;
Var StandardInterfaceComposition;

#EndRegion

#Region Internal

Function InitializeDataToSetUpStandardODataInterfaceComposition() Export
	
	// Filling in tree root rows by metadata object collections.
	AddTreeRootRow("Constant", NStr("vi = 'Hằng';
									|ru = 'Константы';
									|en = 'Constants'; fa = 'ثابت‌ها';
									|it = 'Costanti';
									|pl = 'Constants';
									|tr = 'Sabitler'"), 1, PictureLib.Constant);
	AddTreeRootRow("Catalog", NStr("vi = 'Danh mục';
									|ru = 'Справочники';
									|en = 'Catalogs'; fa = 'فهرست‌ها';
									|it = 'Directory';
									|pl = 'Kartoteki';
									|tr = 'Kataloglar'"), 2, PictureLib.Catalog);
	AddTreeRootRow("Document", NStr("vi = 'Chứng từ';
									|ru = 'Документы';
									|en = 'Documents'; fa = 'اسناد';
									|it = 'Documenti';
									|pl = 'Documents';
									|tr = 'Belgeler'"), 3, PictureLib.Document);
	AddTreeRootRow("DocumentJournal", NStr("vi = 'Nhật ký chứng từ';
											|ru = 'Журналы документов';
											|en = 'Document journals'; fa = 'Document journals';
											|it = 'Registri dei documenti';
											|pl = 'Dzienniki dokumentów';
											|tr = 'Belge günlükleri'"), 4, PictureLib.DocumentJournal);
	AddTreeRootRow("Enum", NStr("vi = 'Liệt kê';
								|ru = 'Перечисление';
								|en = 'Enumeration'; fa = 'Enumeration';
								|it = 'Enumerazione';
								|pl = 'Enumeration';
								|tr = 'Transfer'"), 5, PictureLib.Enum);
	AddTreeRootRow("ChartOfCharacteristicTypes", NStr("vi = 'Hệ thống dạng đặc tính';
														|ru = 'Планы видов характеристик';
														|en = 'Charts of characteristic types'; fa = 'Charts of characteristic types';
														|it = 'Piani dei tipi di caratteristiche';
														|pl = 'Plany rodzajów charakterystyk';
														|tr = 'Özellik türü listeleri'"), 6, PictureLib.ChartOfCharacteristicTypes);
	AddTreeRootRow("ChartOfAccounts", NStr("vi = 'Hệ thống tài khoản';
											|ru = 'Планы счетов';
											|en = 'Charts of accounts'; fa = 'سرفصل‌های حساب';
											|it = 'Piani dei conti';
											|pl = 'Plany rachunków';
											|tr = 'Hesap planları'"), 7, PictureLib.ChartOfAccounts);
	AddTreeRootRow("ChartOfCalculationTypes", NStr("vi = 'Hệ thống dạng tính toán';
													|ru = 'Планы видов расчета';
													|en = 'Charts of calculation types'; fa = 'Charts of calculation types';
													|it = 'Piani dei tipi di calcolo';
													|pl = 'Plany rodzajów obliczeń';
													|tr = 'Hesaplama türü planları'"), 8, PictureLib.ChartOfCalculationTypes);
	AddTreeRootRow("InformationRegister", NStr("vi = 'Biểu ghi thông tin';
												|ru = 'Регистры сведений';
												|en = 'Information registers'; fa = 'ثبت‌های اطلاعاتی';
												|it = 'Registri delle informazioni';
												|pl = 'Rejestry informacji';
												|tr = 'Bilgi kayıtları'"), 9, PictureLib.InformationRegister);
	AddTreeRootRow("AccumulationRegister", NStr("vi = 'Biểu ghi tích lũy';
												|ru = 'Регистры накопления';
												|en = 'Accumulation registers'; fa = 'ثبت‌های انباشتی';
												|it = 'Registri di accumulo';
												|pl = 'Rejestry kumulacji';
												|tr = 'Birikim kayıtları'"), 10, PictureLib.AccumulationRegister);
	AddTreeRootRow("AccountingRegister", NStr("vi = 'Biểu ghi kế toán';
												|ru = 'Регистры бухгалтерии';
												|en = 'Accounting registers'; fa = 'Accounting registers';
												|it = 'Registri contabilità';
												|pl = 'Rejestry księgowości';
												|tr = 'Muhasebe kayıtları'"), 11, PictureLib.AccountingRegister);
	AddTreeRootRow("CalculationRegister", NStr("vi = 'Biểu ghi tính toán';
												|ru = 'Регистры расчета';
												|en = 'Calculation registers'; fa = 'Calculation registers';
												|it = 'Registri di calcolo';
												|pl = 'Rejestry rozliczenia';
												|tr = 'Mutabakat işlemleri kayıtları'"), 12, PictureLib.CalculationRegister);
	AddTreeRootRow("BusinessProcess", NStr("vi = 'Quy trình nghiệp vụ';
											|ru = 'Бизнес-процессы';
											|en = 'Business processes'; fa = 'فرایندهای تجاری';
											|it = 'Processi aziendali';
											|pl = 'Business processes';
											|tr = 'İş süreçleri'"), 13, PictureLib.BusinessProcess);
	AddTreeRootRow("Task", NStr("vi = 'Nhiệm vụ';
								|ru = 'Задачи';
								|en = 'Tasks'; fa = 'وظایف';
								|it = 'Obiettivi';
								|pl = 'Tasks';
								|tr = 'Görevler'"), 14, PictureLib.Task);
	AddTreeRootRow("ExchangePlan", NStr("vi = 'Sơ đồ trao đổi';
										|ru = 'Планы обмена';
										|en = 'Exchange plans'; fa = 'Exchange plans';
										|it = 'Piani di scambio';
										|pl = 'Plany wymiany';
										|tr = 'Değiştirme planları'"), 15, PictureLib.ExchangePlan);
	
	// Read the current content of the standard OData interface.
	SystemComposition = GetStandardODataInterfaceContent();
	StandardInterfaceComposition = New Array();
	For Each Item In SystemComposition Do
		StandardInterfaceComposition.Add(Item.FullName());
	EndDo;
	
	// Read the model of data to provide to the standard OData interface.
	Model = DataProcessors.SetUpStandardODataInterface.ModelOfDataToProvideForStandardODataInterface();
	
	// Populate nested tree rows by model metadata objects.
	For Each ModelItem In Model Do
		
		FullName = ModelItem.FullName;
		IsReadOnlyObject = Not ModelItem.Update;
		IsObjectIncludedInComposition = (StandardInterfaceComposition.Find(ModelItem.FullName) <> Undefined);
		Dependencies = ModelItem.Dependencies;
		
		If Common.MetadataObjectAvailableByFunctionalOptions(FullName) Then
			
			AddNestedTreeRow(FullName, IsReadOnlyObject,
				IsObjectIncludedInComposition, Dependencies);
			
		EndIf;
		
	EndDo;
	
	// Delete root rows from metadata collections that have no objects to include.
	LinesToDelete = New Array();
	For Each TreeRow In ObjectsTree.Rows Do
		If TreeRow.Rows.Count() = 0 Then
			LinesToDelete.Add(TreeRow);
		EndIf;
	EndDo;
	For Each RowToDelete In LinesToDelete Do
		ObjectsTree.Rows.Delete(RowToDelete);
	EndDo;
	
	// Sort nested rows by metadata object presentation.
	For Each NestedRow In ObjectsTree.Rows Do
		NestedRow.Rows.Sort("Presentation");
	EndDo;
	
	Result = New Structure();
	Result.Insert("ObjectsTree", ObjectsTree);
	Result.Insert("AdditionDependencies", AdditionDependencies);
	Result.Insert("DeletionDependencies", DeletionDependencies);
	
	Return Result;
	
EndFunction

#EndRegion

#Region Private

Procedure AddNestedTreeRow(Val FullName, Val ReadOnly, Val Use, Val Dependencies)
	
	NameStructure = StrSplit(FullName, ".");
	ObjectClass = NameStructure[0];
	
	RowOwner = Undefined;
	For Each TreeRow In ObjectsTree.Rows Do
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
	
	NewRow.FullName = FullName;
	NewRow.Presentation = MetadataObjectPresentation(FullName);
	NewRow.Class = RowOwner.Class;
	NewRow.Picture = RowOwner.Picture;
	NewRow.Use = StandardInterfaceComposition.Find(FullName) <> Undefined;
	NewRow.Subordinated = ODataInterfaceInternal.IsRecordSet(FullName)
		And Not IsIndependentRecordSet(FullName);
	NewRow.ReadOnly = ReadOnly;
	NewRow.Use = Use;
	
	For Each ObjectDependency In Dependencies Do
		
		If Common.MetadataObjectAvailableByFunctionalOptions(ObjectDependency) Then
			
			// If add the MetadataObject object, then add the ObjectDependency object.
			String = AdditionDependencies.Add();
			String.ObjectName = FullName;
			String.DependentObjectName = ObjectDependency;
			
			// If remove the MetadataObject object, then remove the ObjectDependency object.
			String = DeletionDependencies.Add();
			String.ObjectName = ObjectDependency;
			String.DependentObjectName = FullName;
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure AddTreeRootRow(Val FullName, Val Presentation, Val Class, Val Picture)
	
	NewRow = ObjectsTree.Rows.Add();
	NewRow.FullName = FullName;
	NewRow.Presentation = Presentation;
	NewRow.Class = Class;
	NewRow.Picture = Picture;
	NewRow.Subordinated = False;
	NewRow.ReadOnly = False;
	NewRow.Root = True;
	
EndProcedure

// Returns a metadata object presentation.
//
// Parameters:
//  MetadataObject.
//
// Returns:
//   String - Metadata object presentation.
//
Function MetadataObjectPresentation(Val MetadataObject) Export
	
	MetadataObjectProperties1 = ODataInterfaceInternal.ConfigurationModelObjectProperties(
		ODataInterfaceInternalCached.ConfigurationDataModelDetails(), MetadataObject);
		
	Return MetadataObjectProperties1.Presentation;
	
EndFunction

// Checks whether the passed metadata object is an independent record set.
//
// Parameters:
//  MetadataObject - Metadata object being checked.
//
// Returns:
//   Boolean
//
Function IsIndependentRecordSet(Val MetadataObject) Export
	
	If TypeOf(MetadataObject) = Type("String") Then
		MetadataObject = Common.MetadataObjectByFullName(MetadataObject);
	EndIf;
	
	Return Common.IsInformationRegister(MetadataObject)
		And MetadataObject.WriteMode = Metadata.ObjectProperties.RegisterWriteMode.Independent;
	
EndFunction

#EndRegion

#Region Initialize

ObjectsTree = New ValueTree();
ObjectsTree.Columns.Add("FullName", New TypeDescription("String"));
ObjectsTree.Columns.Add("Presentation", New TypeDescription("String"));
ObjectsTree.Columns.Add("Class", New TypeDescription("Number", , New NumberQualifiers(10, 0, AllowedSign.Nonnegative)));
ObjectsTree.Columns.Add("Picture", New TypeDescription("Picture"));
ObjectsTree.Columns.Add("Use", New TypeDescription("Boolean"));
ObjectsTree.Columns.Add("Subordinated", New TypeDescription("Boolean"));
ObjectsTree.Columns.Add("ReadOnly", New TypeDescription("Boolean"));
ObjectsTree.Columns.Add("Root", New TypeDescription("Boolean"));

StandardInterfaceComposition = New Array();

AdditionDependencies = New ValueTable();
AdditionDependencies.Columns.Add("ObjectName", New TypeDescription("String"));
AdditionDependencies.Columns.Add("DependentObjectName", New TypeDescription("String"));

DeletionDependencies = New ValueTable();
DeletionDependencies.Columns.Add("ObjectName", New TypeDescription("String"));
DeletionDependencies.Columns.Add("DependentObjectName", New TypeDescription("String"));

#EndRegion

#Else
Raise NStr("vi = 'Lần gọi không hợp lệ đối tượng trên Client.';
			|ru = 'Недопустимый вызов объекта на клиенте.';
			|en = 'Invalid object call on the client.'; fa = 'Invalid object call on the client.';
			|it = 'Chiamata di oggetto non valida sul client.';
			|pl = 'Niedozwolone wezwanie obiektu na kliencie.';
			|tr = 'İstemcide geçersiz nesne çağrısı.'");
#EndIf