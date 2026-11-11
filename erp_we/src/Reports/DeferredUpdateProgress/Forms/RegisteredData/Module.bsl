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
	HandlerName = Parameters.HandlerName;
	If Not ValueIsFilled(HandlerName) Then
		Raise NStr("vi = 'Chưa chuyển tên hàm sự kiện.';
					|ru = 'Не передано имя обработчика.';
					|en = 'Handler name wasn''t passed.'; fa = 'Handler name wasn''t passed.';
					|it = 'Non è stato trasferito il nome dell''gestore.';
					|pl = 'Nie przekazano nazwy procesora danych.';
					|tr = 'İşleyici adı verilmedi.'");
	EndIf;
	
	Title = NStr("vi = 'Dữ liệu đã ghi nhận theo hàm sự kiện %1';
				|ru = 'Зарегистрированные данные по обработчику %1';
				|en = 'Data registered on handler ""%1""'; fa = 'Data registered on handler ""%1""';
				|it = 'Dati registrati per gestore %1';
				|pl = 'Zarejestrowane dane według procesora danych %1';
				|tr = 'İşleyiciye göre kayıtlı veriler%1'");
	Title = StringFunctionsClientServer.SubstituteParametersToString(Title, HandlerName);
	
	TextSummaryInformation = NStr("vi = 'Còn phải xử lý %1 đối tượng trong số %2, tiến trình - %3%. Trong kỳ chỉ định đã xử lý %4.';
									|ru = 'Осталось обработать объектов %1 из %2, прогресс - %3%. За указанный период обработано %4.';
									|en = '%1 out of %2 objects remain to be processed, progress - %3%. %4 objects have been processed for the selected period.'; fa = '%1 out of %2 objects remain to be processed, progress - %3%. %4 objects have been processed for the selected period.';
									|it = 'Restano da elaborare oggetti %1 da%2, progresso %3. Nel periodo indicato sono stati elaborati %4.';
									|pl = 'Pozostało obiektów do przetworzenia %1 z %2, postęp - %3. Za podany okres przetworzono %4.';
									|tr = 'Nesneleri işlemek için kaldı%1dan %2, ilerleme - %3%. Belirtilen süre içinde işlenmiştir%4.'");
	If Not ValueIsFilled(Number(Parameters.ProcessedForPeriod)) Then
		TextSummaryInformation = NStr("vi = 'Còn phải xử lý %1 đối tượng trong số %2, tiến trình - %3%. Trong kỳ chỉ định không có dữ liệu được xử lý.';
										|ru = 'Осталось обработать объектов %1 из %2, прогресс - %3%. За указанный период нет обработанных данных.';
										|en = '%1 out of %2 objects remain to be processed, progress - %3. No data has been processed for the selected period.'; fa = '%1 out of %2 objects remain to be processed, progress - %3. No data has been processed for the selected period.';
										|it = 'Restano da elaborare oggetti %1 da%2, progresso %3. Nel periodo indicato non ci sono dati elaborati.';
										|pl = 'Pozostało obiektów do przetworzenia %1 z %2, postęp - %3. Za podany okres nie ma przetworzonych danych.';
										|tr = '%2 dan %1nesneleri işlemek için kalır, ilerleme -%3%. Belirtilen süre için işlenmiş veri yok.'");
	EndIf;
	
	Items.CaptionSummaryInformation.Title = StringFunctionsClientServer.SubstituteParametersToString(
		TextSummaryInformation,
		Parameters.LeftToProcess,
		Parameters.TotalObjectCount,
		Parameters.Progress,
		Parameters.ProcessedForPeriod);
	
	Query = New Query;
	Query.SetParameter("HandlerName", HandlerName);
	Query.Text =
		"SELECT
		|	UpdateHandlers.HandlerName AS HandlerName,
		|	UpdateHandlers.DeferredProcessingQueue AS Queue,
		|	UpdateHandlers.DataToProcess AS DataToProcess
		|FROM
		|	InformationRegister.UpdateHandlers AS UpdateHandlers
		|WHERE
		|	UpdateHandlers.HandlerName = &HandlerName";
	Result = Query.Execute().Unload();
	
	HandlerDetails = Result[0];
	Queue = HandlerDetails.Queue;
	DataToProcess = HandlerDetails.DataToProcess.Get();
	For Each ObjectData2 In DataToProcess.HandlerData Do
		FullObjectName = ObjectData2.Key;
		Items.TableName.ChoiceList.Add(FullObjectName);
	EndDo;
	
	TableName = Items.TableName.ChoiceList[0].Value;
	SetListRequest();
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure TableNameOnChange(Item)
	SetListRequest();
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetListRequest()
	
	ObjectMetadata = Common.MetadataObjectByFullName(TableName);
	IsReferenceObject = Common.IsRefTypeObject(ObjectMetadata);
	
	For Each AddedElement In AddedItems Do
		Item = Items.Find(AddedElement.Value);
		Items.Delete(Item);
	EndDo;
	
	AddedItems.Clear();
	
	QueryTemplate =
		"SELECT
		|	*
		|FROM
		|	&TableName AS ChangesTable1
		|WHERE
		|	ChangesTable1.Node = &Node";
	ChangeTableName = TableName + ".Changes";
	
	QueryText = StrReplace(QueryTemplate, "&TableName", ChangeTableName);
	Node = ExchangePlans.InfobaseUpdate.NodeInQueue(Queue);
	
	Properties = Common.DynamicListPropertiesStructure();
	Properties.QueryText = QueryText;
	Properties.DynamicDataRead = True;
	Common.SetDynamicListProperties(Items.List, Properties);
	CommonClientServer.SetDynamicListParameter(
		List, "Node", Node, True);
	
	Parent = Items.List;
	If Not IsReferenceObject Then
		StructureToCheck = New Structure;
		StructureToCheck.Insert("MainFilter", Undefined);
		For Each Dimension In ObjectMetadata.Dimensions Do // MetadataObjectDimension
			FillPropertyValues(StructureToCheck, Dimension);
			If StructureToCheck.MainFilter = Undefined
				Or Not StructureToCheck.MainFilter Then
				Continue;
			EndIf;
			
			NewItem = Items.Add("List" + Dimension.Name, Type("FormField"), Parent);
			NewItem.DataPath = "List" + "." + Dimension.Name;
			AddedItems.Add(NewItem.Name);
		EndDo;
		
		For Each StandardAttribute In ObjectMetadata.StandardAttributes Do // StandardAttributeDescription
			If StandardAttribute.Name = "Recorder" Then
				NewItem = Items.Add("List" + StandardAttribute.Name, Type("FormField"), Parent);
				NewItem.DataPath = "List" + "." + StandardAttribute.Name;
				AddedItems.Add(NewItem.Name);
				Break;
			EndIf;
		EndDo;
	Else
		NewItem = Items.Add("ListRef", Type("FormField"), Parent);
		NewItem.DataPath = "List" + "." + "Ref";
		AddedItems.Add(NewItem.Name);
	EndIf;
	
EndProcedure

#EndRegion