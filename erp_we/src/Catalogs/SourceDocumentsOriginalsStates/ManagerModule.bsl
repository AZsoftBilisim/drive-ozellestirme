///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// See also InfobaseUpdateOverridable.OnSetUpInitialItemsFilling.
// 
// Parameters:
//  Settings - See InfobaseUpdateOverridable.OnSetUpInitialItemsFilling.Settings
//
Procedure OnSetUpInitialItemsFilling(Settings) Export

	Settings.OnInitialItemFilling = False;

EndProcedure

// See also InfobaseUpdateOverridable.OnInitialItemsFilling
// 
// Parameters:
//   LanguagesCodes - See InfobaseUpdateOverridable.OnInitialItemsFilling.LanguagesCodes
//   Items - See InfobaseUpdateOverridable.OnInitialItemsFilling.Items
//   TabularSections - See InfobaseUpdateOverridable.OnInitialItemsFilling.TabularSections
//
Procedure OnInitialItemsFilling(LanguagesCodes, Items, TabularSections) Export

	Item = Items.Add();
	Item.PredefinedDataName = "FormPrinted";
	Item.Description = NStr("vi = 'Biểu mẫu được in';
							|ru = 'Форма напечатана';
							|en = 'Form printed'; fa = 'Form printed';
							|it = 'Modulo stampato';
							|pl = 'Wydrukowano formularz';
							|tr = 'Form yazdırıldı'", Common.DefaultLanguageCode());
	Item.LongDesc = NStr("vi = 'Trạng thái cho thấy mẫu in mẫu in chỉ được in.';
						|ru = 'Состояние, означающее, что  печатная форма только печаталась.';
						|en = 'State that means that the print form was printed only.'; fa = 'State that means that the print form was printed only.';
						|it = 'Stato che indica che il modulo di stampa è stato solo stampato.';
						|pl = 'Status, oznaczający, że formularz wydruku była tylko drukowana.';
						|tr = 'Yazdırma formunun yeni yazdırıldığı anlamına gelen durum'", Common.DefaultLanguageCode());
	Item.Code = "000000001";
	Item.AddlOrderingAttribute = "1";

	Item = Items.Add();
	Item.PredefinedDataName = "OriginalsNotAll";
	Item.Description = NStr("vi = 'Tất cả không phải là bản gốc';
							|ru = 'Оригиналы не все';
							|en = 'Not all originals'; fa = 'Not all originals';
							|it = 'Originali non tutti';
							|pl = 'Nie wszystkie oryginały';
							|tr = 'Asılların hepsi değil'", Common.DefaultLanguageCode());
	Item.LongDesc = NStr("vi = 'Trạng thái chung đối với chứng từ, trong đó các bản gốc của mẫu in có các trạng thái khác nhau.';
						|ru = 'Общее состояние для документа, у которого оригиналы печатных форм находятся в разных состояниях.';
						|en = 'The aggregated state of a document whose print forms have different states.'; fa = 'The aggregated state of a document whose print forms have different states.';
						|it = 'Stato generale per il documento di cui gli originali dei moduli di stampa sono negli stati diversi.';
						|pl = 'Ogólny status dla dokumentu, który nie ma oryginałów formularzy wydruku ma różne statusy.';
						|tr = 'Yazdırma formlarının asılları farklı durumlarda olan bir belgenin paylaşımlı durumu.'", Common.DefaultLanguageCode());
	Item.Code = "000000002";
	Item.AddlOrderingAttribute = "99998";

	Item = Items.Add();
	Item.PredefinedDataName = "OriginalReceived";
	Item.Description = NStr("vi = 'Đã nhận bản gốc';
							|ru = 'Оригинал получен';
							|en = 'Original received'; fa = 'Original received';
							|it = 'Originale ricevuto';
							|pl = 'Otrzymano oryginał';
							|tr = 'Aslı alındı'", Common.DefaultLanguageCode());
	Item.LongDesc = NStr("vi = 'Tình trạng chỉ ra rằng bản gốc có chữ ký của biểu mẫu in vẫn còn.';
						|ru = 'Состояние, означающее, что подписанный оригинал печатной формы есть в наличии.';
						|en = 'State that means that the signed print form original is available.'; fa = 'State that means that the signed print form original is available.';
						|it = 'Stato che indica che l''originale firmato del modulo di stampa è presente.';
						|pl = 'Status, oznaczający, że podpisany oryginał formularza wydruku jest w posiadaniu.';
						|tr = 'Yazdırma formunun imzalı aslının mevcut olduğunu gösteren durum.'", Common.DefaultLanguageCode());
	Item.Code = "000000003";
	Item.AddlOrderingAttribute = "99999";

EndProcedure


#Region UpdateHandlers

// Registers in the InfobaseUpdate exchange plan the objects to update.
// 
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	Query = New Query;
	Query.Text =
		"SELECT
		|	SourceDocumentsOriginalsStates.Ref AS Ref
		|FROM
		|	Catalog.SourceDocumentsOriginalsStates AS SourceDocumentsOriginalsStates
		|
		|ORDER BY
		|	SourceDocumentsOriginalsStates.AddlOrderingAttribute";
	
	Result = Query.Execute().Unload();
	ReferencesArrray = Result.UnloadColumn("Ref");
	
	InfobaseUpdate.MarkForProcessing(Parameters, ReferencesArrray);
	
EndProcedure

// Set value for attribute AddlOrderingAttribute of catalog SourceDocumentsOriginalsStates.
// 
Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
		
	Selection = InfobaseUpdate.SelectRefsToProcess(Parameters.Queue, "Catalog.SourceDocumentsOriginalsStates");
	
	StateOfOrder = New ValueTable();
	StateOfOrder.Columns.Add("Ref");
	StateOfOrder.Columns.Add("Order");

	While Selection.Next() Do
		CurState = StateOfOrder.Add();
		CurState.Ref = Selection.Ref;
	EndDo;
	
	References = StateOfOrder.UnloadColumn("Ref");
	AttributesOrder = Common.ObjectsAttributeValue(References, "AddlOrderingAttribute"); 
	
	For Each State In StateOfOrder Do
		CrntOrder = AttributesOrder.Get(State.Ref);
		State.Order = CrntOrder;
	EndDo;
	
	StateOfOrder.Sort("Order");
	
	ObjectsWithIssuesCount = 0;
	ObjectsProcessed = 0;
	
	Order = 2;
	
	For Each IsmStatus In StateOfOrder Do
		RepresentationOfTheReference = String(IsmStatus.Ref);
		Try
			
			If IsmStatus.Ref = Catalogs.SourceDocumentsOriginalsStates.FormPrinted Then
				FillInTheDetailsOfTheAdditionalOrderingDetails(IsmStatus, 1);
				ObjectsProcessed = ObjectsProcessed + 1;
			ElsIf IsmStatus.Ref = Catalogs.SourceDocumentsOriginalsStates.OriginalsNotAll Then
				FillInTheDetailsOfTheAdditionalOrderingDetails(IsmStatus, 99998);
				ObjectsProcessed = ObjectsProcessed + 1;
			ElsIf IsmStatus.Ref = Catalogs.SourceDocumentsOriginalsStates.OriginalReceived Then
			    FillInTheDetailsOfTheAdditionalOrderingDetails(IsmStatus, 99999);
				ObjectsProcessed = ObjectsProcessed + 1;
			Else
				FillInTheDetailsOfTheAdditionalOrderingDetails(IsmStatus, Order);
				ObjectsProcessed = ObjectsProcessed + 1;
				Order = Order + 1;
			EndIf;
			
		Except
			// If procession failed, try again.
			ObjectsWithIssuesCount = ObjectsWithIssuesCount + 1;
			
			InfobaseUpdate.WriteErrorToEventLog(
				IsmStatus.Ref,
				RepresentationOfTheReference,
				ErrorInfo());
		EndTry;
		
	EndDo;
	
	Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, "Catalog.SourceDocumentsOriginalsStates");
	If ObjectsProcessed = 0 And ObjectsWithIssuesCount <> 0 Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể xử lý một số trạng thái của bản gốc chứng từ (đã bỏ qua): %1';
				|ru = 'Не удалось обработать некоторые состояния оригиналов первичных документов (пропущены): %1';
				|en = 'Couldn''t process (skipped) some states of primary documents: %1'; fa = 'Couldn''t process (skipped) some states of primary documents: %1';
				|it = 'Non è stato possibile elaborare alcuni stati degli originali dei documeni primari (saltati): %1';
				|pl = 'Nie udało się przetworzyć niektórych statusów oryginałów pierwotnych dokumentów (pominięte): %1';
				|tr = 'Birincil belge asıllarının bazı durumları işlenemedi (atlandı): %1'"), 
				ObjectsWithIssuesCount);
		Raise MessageText;
	Else
		WriteLogEvent(InfobaseUpdate.EventLogEvent(), EventLogLevel.Information,
			Metadata.Catalogs.SourceDocumentsOriginalsStates,,
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Đã xử lý tùy chọn theo trình tự trạng thái bản gốc chứng từ: %1';
						|ru = 'Обработана очередная порция состояния оригиналов первичных документов: %1';
						|en = 'Yet another batch of states of primary documents is processed: %1'; fa = 'Yet another batch of states of primary documents is processed: %1';
						|it = 'È stata elaborata un''altra porzione di stato degli originali dei documenti primari: %1';
						|pl = 'Przetworzono kolejną część statusów oryginałłów pierwotnych dokumentów: %1';
						|tr = 'Birincil belge asıllarının durumunun başka bir bölümü işlendi: %1'"),
					ObjectsProcessed));
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

// In the passed item, re-populate internal attribute AddlOrderingAttribute.
//
Procedure FillInTheDetailsOfTheAdditionalOrderingDetails(Selection, Order)
	
	BeginTransaction();
	Try
	
		// Lock the object (to ensure that it won't be edited in other sessions).
		Block = New DataLock;
		LockItem = Block.Add("Catalog.SourceDocumentsOriginalsStates");
		LockItem.SetValue("Ref", Selection.Ref);
		Block.Lock();
		
		TheStateOfTheObject = Selection.Ref.GetObject();
		
		// Process object.
		TheStateOfTheObject.AddlOrderingAttribute = Order;
		
		// Write processed object.
		InfobaseUpdate.WriteData(TheStateOfTheObject);
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

#EndRegion

#EndIf