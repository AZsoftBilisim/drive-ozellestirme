// @strict-types

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)
	
	If GoodsDeliveryClientServer.UsedDelivery25() Then
		
		ExceptionText = NStr("vi = 'Chứng từ không được hỗ trợ trong bản phân phối phiên bản 2.5';
							|ru = 'Документ не поддерживается в доставке версии 2.5';
							|en = 'The document is not supported in delivery version 2.5'; fa = 'The document is not supported in delivery version 2.5';
							|it = 'The document is not supported in delivery version 2.5';
							|pl = 'The document is not supported in delivery version 2.5';
							|tr = 'Teslimat 2.5 sürümünde belge desteklenmiyor'");
		Raise ExceptionText;
		
	EndIf;
	
	If TypeOf(FillingData) = Type("Array") Then
		For Each Basis In FillingData Do
			If Common.IsDocument(Basis.Metadata()) Then
				NewRow = Basis1.Add();
				NewRow.Basis = Basis;
			EndIf;
		EndDo;
		
		If Basis1.Count() > 0 Then
			
			BaseData = Documents.InstructionForShippingAgent.BaseData(Basis1.UnloadColumn("Basis"));
			
			If BaseData.Items_2.Count() > 0 Then
				Point = BaseData.Items_2[0];
			EndIf;
			If BaseData.Warehouses.Count() > 0 Then
				Warehouse = BaseData.Warehouses[0];
			Else
				Warehouse = Catalogs.Warehouses.DefaultWarehouse();
			EndIf;
			If BaseData.Contacts.Count() > 0 Then
				ContactPerson = BaseData.Contacts[0];
			EndIf;
			If BaseData.TransportMethods.Count() = 1 Then
				DeliveryMethod = BaseData.TransportMethods[0];
			EndIf;
			
			If Basis1.Count() = 1 Then
				
				DeliveryFields = New Array; // Array of String
				DeliveryFields.Add("DeliveryAddress");
				DeliveryFields.Add("DeliveryAddressFieldValues");
				DeliveryFields.Add("DeliveryTimeTo");
				DeliveryFields.Add("DeliveryTimeFrom");
				DeliveryFields.Add("AdditionalDeliveryInformation");
				DeliveryFields.Add("DeliveryZone");
				
				AvailableDeliveryFields = New Array();
				
				CurrentBasis = Basis1[0].Basis;
				MetadataBases_ = CurrentBasis.Metadata();
				
				For Each FieldName In DeliveryFields Do
					If Common.HasObjectAttribute(FieldName, MetadataBases_) Then
						AvailableDeliveryFields.Add(FieldName);
					EndIf;
				EndDo;
				
				If AvailableDeliveryFields.Count() > 0 Then
					DeliveryProperties = Common.ObjectAttributesValues(CurrentBasis, AvailableDeliveryFields);
					FieldsForFillingDeliveryWithString = StrConcat(AvailableDeliveryFields, ",");
					FillPropertyValues(ThisObject, DeliveryProperties, FieldsForFillingDeliveryWithString);
				EndIf;
				
			EndIf;
			
			Return;
		ElsIf FillingData.Count() = 1 Then
			FillingData = FillingData[0];
		Else
			Return;
		EndIf;
		
	EndIf;
	
	If TypeOf(FillingData) = Type("CatalogRef.Warehouses") Then
		If ValueIsFilled(FillingData)
			And Common.ObjectAttributeValue(FillingData, "IsFolder") Then
			
			Raise NStr("vi = 'Không được cung cấp đơn đặt hàng cho người giao nhận dựa trên một nhóm kho.';
						|ru = 'Не предусмотрен ввод поручения экспедитору на основании группы складов.';
						|en = 'Entry of delivery request based on the warehouse group is not available.'; fa = 'Entry of delivery request based on the warehouse group is not available.';
						|it = 'Non è prevista l''immissione del task a spedizioniere in base ad un gruppo di magazzini.';
						|pl = 'Nie jest przewidziane wprowadzanie zlecenia do spedytora na podstawie grupy magazynowej.';
						|tr = 'Ambar grubu esasında teslimat talebine sipariş girilmesi öngörülmemiştir.'");
			
		Else
			Point = FillingData;
			Warehouse = FillingData;
			DeliveryMethod = Enums.TransportMethods.InstructionForShippingAgentAtPoint;
		EndIf;
	ElsIf TypeOf(FillingData) = Type("CatalogRef.Partners")
		  Or TypeOf(FillingData) = Type("CatalogRef.BusinessStructure") Then
		
		Point = FillingData;
		DeliveryMethod = Enums.TransportMethods.InstructionForShippingAgentAtPoint;
		
	EndIf;
	
	If ValueIsFilled(Point)
	   And Not ValueIsFilled(ContactPerson)
	   And TypeOf(Point) = Type("CatalogRef.Partners") Then
		PartnersAndCounterparties.FillInDefaultPartnerContactPerson(Point, ContactPerson);
	EndIf;
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	If GoodsDeliveryClientServer.UsedDelivery25() Then
		
		// in delivery version 2.5, it is forbidden to write the document as a whole, See BeforeWrite
		CheckedAttributes.Clear();
		Return;
		
	EndIf;
	
	NotCheckedAttributeArray = New Array; // Array of String
	
	If DeliveryMethod = Enums.TransportMethods.InstructionForShippingAgentAtPoint Then
		NotCheckedAttributeArray.Add("Warehouse");
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	GoodsDelivery.ReflectDeliveryState(Ref, Cancel);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	GoodsDelivery.ReflectDeliveryState(Ref, Cancel, True);
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If GoodsDeliveryClientServer.UsedDelivery25() Then
		
		MessageText = NStr("vi = 'Thay đổi chứng từ không được hỗ trợ trong bản phân phối phiên bản 2.5';
							|ru = 'Изменение документа не поддерживается в доставке версии 2.5';
							|en = 'Changing the document is not supported in delivery version 2.5'; fa = 'Changing the document is not supported in delivery version 2.5';
							|it = 'Changing the document is not supported in delivery version 2.5';
							|pl = 'Changing the document is not supported in delivery version 2.5';
							|tr = 'Teslimat 2.5 sürümünde belge değişikliği desteklenmiyor'");
		Common.MessageToUser(MessageText, ThisObject,,, Cancel);
		Return;
		
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	If DeliveryMethod = Enums.TransportMethods.InstructionForShippingAgentAtPoint Then
		Warehouse = Catalogs.Warehouses.EmptyRef();
	EndIf;
	
	If Not ValueIsFilled(ExecutionDate) Then
		ExecutionDate = Date;
	EndIf;
	
EndProcedure

#EndRegion

#EndIf
