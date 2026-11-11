// @strict-types

#Region Public

// Indicates that any delivery is being used in the system
// 
// Returns:
//  Boolean 
//
Function UsedDelivery() Export
	
	Return GoodsDeliveryServerCallCached.UsedDelivery();
	
EndFunction

// Indicates that version 2.0 delivery is being used in the system
// 
// Returns:
//  Boolean 
//
Function UsedDelivery20() Export
	
	Return GoodsDeliveryServerCallCached.UsedDelivery20();
	
EndFunction

// Indicates that version 2.5 delivery is being used in the system
// 
// Returns:
//  Boolean 
//
Function UsedDelivery25() Export
	
	Return GoodsDeliveryServerCallCached.UsedDelivery25();
	
EndFunction

// Determines the need for delivery of operation in the document
// 
// Parameters:
//  Operation - EnumRef.BusinessTransactions - 
// 
// Returns:
//  Boolean - A Business Transaction Is Involved In Delivery
//
Function BusinessTransactionIsInvolvedInDelivery(Operation) Export
	
	ThisIsDocumentOperationWithoutDelivery =
		(Operation = PredefinedValue("Enum.BusinessTransactions.EmptyRef")
			Or Operation = PredefinedValue("Enum.BusinessTransactions.SalesViaCommissionAgent")
			Or Operation = PredefinedValue("Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit")
			Or Operation = PredefinedValue("Enum.BusinessTransactions.SaleToCustomerLocalAccounting")
			Or Operation = PredefinedValue("Enum.BusinessTransactions.TransferOfTitleToGoods")
			Or Operation = PredefinedValue("Enum.BusinessTransactions.DeliveryForPrincipal"));
	
	Return Not ThisIsDocumentOperationWithoutDelivery;
	
EndFunction

#Region Delivery20

// Sets the delivery page depending on the delivery method.
//
// Parameters:
//  FormItems - FormAllItems - elements of the form where the delivery page is set.
//  DeliveryMethod - EnumRef.TransportMethods	 - the delivery method that
//  	the delivery page is selected for.
//  UseTransportationJobsForDeliveryAccountingByCarriers	 - Boolean - True, indicates that transportation tasks are used
//  	to account for delivery to carriers.
//  ThisIsOrderByAgreement - Boolean - indicates that the order is an agreement.
//  ThisIsOrderUnderContract - Boolean - indicates that the order is a contract.
//
Procedure SetDeliveryPage(FormItems,
		DeliveryMethod,
		UseTransportationJobsForDeliveryAccountingByCarriers = Undefined,
		ThisIsOrderByAgreement = False,
		ThisIsOrderUnderContract = False) Export
	
	DeliveryPages = FormItems.DeliveryPages; // FormGroupExtensionForPages
	
	If ThisIsOrderByAgreement
	 Or ThisIsOrderUnderContract Then
		
		If FormItems.Find("DeliverySummaryGroup") <> Undefined Then
			DeliveryPages.CurrentPage = FormItems.DeliverySummaryGroup;
		EndIf;
		If FormItems.Find("GroupDeliveryMethodCarrier") <> Undefined Then
			FormItems.GroupDeliveryMethodCarrier.Visible = False;
		EndIf;
		If ThisIsOrderByAgreement
		   And FormItems.Find("LabelGroupSettingDeliveryParameters") <> Undefined Then
			FormItems.LabelGroupSettingDeliveryParameters.CurrentPage = FormItems.LabelGroupSettingDeliveryParametersAgreement;
		ElsIf Not ThisIsOrderByAgreement
				And FormItems.Find("LabelGroupSettingDeliveryParameters") <> Undefined Then
			FormItems.LabelGroupSettingDeliveryParameters.CurrentPage = FormItems.GroupLabelSettingDeliveryParametersContract;
		EndIf;
		
	Else
		
		If FormItems.Find("GroupDeliveryMethodCarrier") <> Undefined Then
			FormItems.GroupDeliveryMethodCarrier.Visible = True;
		EndIf;
		
		If FormItems.Find("PagesCarrier") <> Undefined Then
			
			PagesCarrier = FormItems.PagesCarrier; // FormGroupExtensionForPages
			
			If DeliveryMethod = PredefinedValue("Enum.TransportMethods.ByCarrier")
			 Or DeliveryMethod = PredefinedValue("Enum.TransportMethods.ByCarrierToAddress")
			 Or DeliveryMethod = PredefinedValue("Enum.TransportMethods.ByCarrierToOurWarehouse")
			 Or DeliveryMethod = PredefinedValue("Enum.TransportMethods.ByCarrierToTransferPoint") Then
				
				PagesCarrier.CurrentPage = FormItems.CarrierPage;
				
			Else
				
				PagesCarrier.CurrentPage = FormItems.CarrierPageIsEmpty;
				
			EndIf;
		EndIf;
		
		If (DeliveryMethod = PredefinedValue("Enum.TransportMethods.ToCustomerByCourier"))
		   And (FormItems.Find("PageDeliveryToTheRecipientByCourier") <> Undefined) Then
			
			PagesCarrier = FormItems.PagesCarrier; // FormGroupExtensionForPages
			PagesCarrier.CurrentPage = FormItems.CourierPage;
			
		EndIf;
		
		If (DeliveryMethod = PredefinedValue("Enum.TransportMethods.ToCustomer")
			  Or DeliveryMethod = PredefinedValue("Enum.TransportMethods.ToCustomerIsDefinedByTransportationCompany"))
		   And FormItems.Find("PageDeliveryToRecipient") <> Undefined Then
			
			DeliveryPages.CurrentPage = FormItems.PageDeliveryToRecipient;
			
		ElsIf (DeliveryMethod = PredefinedValue("Enum.TransportMethods.ToCustomerByCourier"))
			And (FormItems.Find("PageDeliveryToTheRecipientByCourier") <> Undefined) Then
			DeliveryPages.CurrentPage = FormItems.PageDeliveryToTheRecipientByCourier;
			
		ElsIf DeliveryMethod = PredefinedValue("Enum.TransportMethods.ByCarrier")
				And FormItems.Find("PageDeliveryByCarrier") <> Undefined Then
			
			DeliveryPages.CurrentPage = FormItems.PageDeliveryByCarrier;
			
		ElsIf DeliveryMethod = PredefinedValue("Enum.TransportMethods.ByCarrierToAddress") Then
			
			If FormItems.Find("PageDeliveryToAddress") <> Undefined Then
				DeliveryPages.CurrentPage = FormItems.PageDeliveryToAddress;
			ElsIf FormItems.Find("PageDeliveryByCarrier") <> Undefined Then
				DeliveryPages.CurrentPage = FormItems.PageDeliveryByCarrier;
			EndIf;
			
		ElsIf DeliveryMethod = PredefinedValue("Enum.TransportMethods.OurOwnDeliveryFromSenderAddress")
			  Or DeliveryMethod = PredefinedValue("Enum.TransportMethods.ByCarrierToTransferPoint")
			  Or DeliveryMethod = PredefinedValue("Enum.TransportMethods.FromSenderDeterminedByDeliveryService") Then
			
			DeliveryPages.CurrentPage = FormItems.OurOwnDeliveryPage;
			If DeliveryMethod = PredefinedValue("Enum.TransportMethods.ByCarrierToTransferPoint") Then
				FormItems.PagesTransferAddress.CurrentPage = FormItems.PageCarrierAddress;
			Else
				FormItems.PagesTransferAddress.CurrentPage = FormItems.PageSupplierAddress;
			EndIf;
			
		ElsIf FormItems.Find("PagePickup") <> Undefined Then
			
			DeliveryPages.CurrentPage = FormItems.PagePickup;
			
		ElsIf FormItems.Find("PageNotOurOwnDelivery") <> Undefined Then
			
			DeliveryPages.CurrentPage = FormItems.PageNotOurOwnDelivery;
			
		EndIf;
	EndIf;
	
	If FormItems.Find("DeliveryPages") <> Undefined Then
		FormItems.DeliveryPages.Visible =
			Not (DeliveryMethod = PredefinedValue("Enum.TransportMethods.DeterminedInReference"));
	EndIf;
	
	If UseTransportationJobsForDeliveryAccountingByCarriers = Undefined
	 Or FormItems.Find("DeliveryPage") = Undefined Then
		Return;
	EndIf;
	
	If ShippingIsUsed(DeliveryMethod, UseTransportationJobsForDeliveryAccountingByCarriers) Then
		FormItems.DeliveryPage.Picture = PictureLib.Comment;
	Else
		FormItems.DeliveryPage.Picture = New Picture;
	EndIf;
	
EndProcedure

// Returns a structure of details of the shipping, filled with empty values.
//
// Parameters:
//  DocObject	 - DocumentObject, FormDataStructure - data of the object document.
//  UseDeliveryManagement - Boolean - indicates that Delivery Management is in use.
// 
// Returns:
//  Structure - Get An Empty Structure Of Delivery Details:
// * DeliveryMethod - EnumRef.TransportMethods - 
// * DeliveryMethodObject_ - EnumRef.TransportMethods - 
// * DeliveryZone - CatalogRef.DeliveryZones - 
// * DeliveryTimeFrom - Date - 
// * DeliveryTimeTo - Date - 
// * CarrierPartner - CatalogRef.Partners - 
// * DeliveryAddress - String - 
// * DeliveryAddressValue - String - 
// * DeliveryAddressOfCarrier - String - 
// * DeliveryAddressOfCarrierValue - String - 
// * DeliveryAddressFieldValues - String - 
// * DeliveryAddressOfCarrierFieldValues - String - 
// * AdditionalDeliveryInformation - String - 
// * SpecialTransportationConditions - Boolean - 
// * SpecialTransportationConditionsDescription - String - 
// * Courier - CatalogRef.Persons - 
//
Function GetEmptyStructureOfDeliveryDetails(DocObject = Undefined, UseDeliveryManagement = True) Export
	
	DeliveryDetails_ = New Structure;
	
	If ThisIsDeliveryOrderToOurWarehouse(DocObject) Then
		DeliveryDetails_.Insert("DeliveryMethod", PredefinedValue("Enum.TransportMethods.ByVendorToOurWarehouse"));
	ElsIf ThisIsInstructionForShippingAgent(DocObject) Then
		DeliveryDetails_.Insert("DeliveryMethod", PredefinedValue("Enum.TransportMethods.InstructionForShippingAgentFromWarehouse"));
	Else
		DeliveryDetails_.Insert("DeliveryMethod",PredefinedValue("Enum.TransportMethods.SelfPickup"));
	EndIf;
	
	DeliveryDetails_.Insert("DeliveryAddress", "");
	DeliveryDetails_.Insert("DeliveryAddressValue", "");
	DeliveryDetails_.Insert("DeliveryAddressFieldValues", "");
	
	If UseDeliveryManagement Then
		DeliveryDetails_.Insert("DeliveryMethodObject_", PredefinedValue("Enum.TransportMethods.SelfPickup"));
		DeliveryDetails_.Insert("DeliveryZone", PredefinedValue("Catalog.DeliveryZones.EmptyRef"));
		DeliveryDetails_.Insert("DeliveryTimeFrom", Date(1,1,1));
		DeliveryDetails_.Insert("DeliveryTimeTo", Date(1,1,1));
		DeliveryDetails_.Insert("CarrierPartner", PredefinedValue("Catalog.Partners.EmptyRef"));
		DeliveryDetails_.Insert("DeliveryAddressOfCarrier", "");
		DeliveryDetails_.Insert("DeliveryAddressOfCarrierValue", "");
		DeliveryDetails_.Insert("DeliveryAddressOfCarrierFieldValues", "");
		DeliveryDetails_.Insert("AdditionalDeliveryInformation", "");
		DeliveryDetails_.Insert("SpecialTransportationConditions", False);
		DeliveryDetails_.Insert("SpecialTransportationConditionsDescription", "");
		
		// AssemblyAndDelivery
		DeliveryDetails_.Insert("Courier", PredefinedValue("Catalog.Persons.EmptyRef"));
		// End AssemblyAndDelivery
	EndIf;
	
	Return DeliveryDetails_;
	
EndFunction

// Searches the list of values for a structure element whose property value is equal to the one you are looking for.
// If no such value is found, it is returned Undefined.
//
// Parameters:
//	List - ValueList of Arbitrary - the list in which the search is performed
//	StructureFieldName - String - the name of the structure property you are looking for
//	SoughtValue - Arbitrary - the value to be found
//
// Returns:
// 	- Undefined -
//	- Structure - a structure whose property values match the one you are looking for, if there are several of them, the first one found is returned.
//
Function FindInListOfStructures(List, StructureFieldName, SoughtValue) Export
	
	Var ValueFound; // Arbitrary
	
	For Each Item In List Do
		Item.Value.Property(StructureFieldName, ValueFound);
		If ValueFound = SoughtValue Then
			Return Item;
		EndIf;
	EndDo;
	
	Return Undefined;
	
EndFunction

// Clears the delivery address selection lists and delivery details.
//
// Parameters:
//	FormItems - FormAllItems - the form, which clears the selection lists of delivery addresses;
//	DocObject - DocumentObject - the object where the delivery details are cleared.
//
Procedure ClearDeliveryDetails(FormItems, DocObject) Export
	
	ClearRecipientSenderAddressSelectionLists(FormItems);
	If FormItems.Find("DeliveryAddressOfCarrier") <> Undefined Then
		FormItems.DeliveryAddressOfCarrier.ChoiceList.Clear();
	EndIf;
	
	FillPropertyValues(DocObject, GetEmptyStructureOfDeliveryDetails(DocObject));
	
	If FormItems.Find("DeliveryPages") <> Undefined Then
		SetDeliveryPage(FormItems, DocObject.DeliveryMethod);
	EndIf;
	
EndProcedure

// Clears the delivery address selection lists.
//
// Parameters:
//	FormItems - FormAllItems - the form, which clears the selection lists of delivery addresses.
//
Procedure ClearRecipientSenderAddressSelectionLists(FormItems) Export
	
	If FormItems.Find("DeliveryAddressSelfPickup") <> Undefined Then
		FormItems.DeliveryAddressSelfPickup.ChoiceList.Clear();
	EndIf;
	If FormItems.Find("RecipientDeliveryAddress") <> Undefined Then
		FormItems.RecipientDeliveryAddress.ChoiceList.Clear();
	EndIf;
	If FormItems.Find("DeliveryAddress") <> Undefined Then
		FormItems.DeliveryAddress.ChoiceList.Clear();
	EndIf;
	If FormItems.Find("RecipientDeliveryAddress1") <> Undefined Then
		FormItems.RecipientDeliveryAddress1.ChoiceList.Clear();
	EndIf;
	If FormItems.Find("RecipientDeliveryAddress2") <> Undefined Then
		FormItems.RecipientDeliveryAddress2.ChoiceList.Clear();
	EndIf;
	If FormItems.Find("SupplierSAddress") <> Undefined Then
		FormItems.SupplierSAddress.ChoiceList.Clear();
	EndIf;
	If FormItems.Find("ItemAddress") <> Undefined Then
		FormItems.ItemAddress.ChoiceList.Clear();
	EndIf;
	
EndProcedure

// Returns a list of values. Converts a string of fields separated by a newline character to a list of values.
//
// Parameters:
//	FieldsString - String - a string where each field starts with a new line.
//
// Returns:
//	ValueList - a list of field values.
//
Function ConvertStringToFieldsList(FieldsString) Export
	
	If ContactsManagerClientServer.IsXMLContactInformation(FieldsString) Then
		Return FieldsString; // the string is in a new format, you do not need to put it in a list
	EndIf;
	
	Result = New ValueList;
	LastItem = Undefined;
	
	For Iteration = 1 To StrLineCount(FieldsString) Do
		ReceivedString = StrGetLine(FieldsString, Iteration);
		If Left(ReceivedString, 1) = Chars.Tab Then
			If LastItem <> Undefined Then
				LastItem.Value = LastItem.Value + Chars.LF + Mid(ReceivedString, 2);
			EndIf;
		Else
			CharPosition = StrFind(ReceivedString, "=");
			If CharPosition <> 0 Then
				LastItem = Result.Add(Mid(ReceivedString, CharPosition + 1), Left(ReceivedString, CharPosition - 1));
			EndIf;
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

// Returns the names of documents that may be delivery orders.
//
// Returns:
//	Array of See DescriptionOfDeliveryOrder
//
Function DescriptionsOfDeliveryOrders() Export
	
	DetailsList1 = New Array; // Array of See DescriptionOfDeliveryOrder
	
	
	LongDesc = DescriptionOfDeliveryOrder();
	LongDesc.Name = "SubcontractOrder2_5";
	LongDesc.ThisIsOrder = True;
	LongDesc.TSName = "SupplyWithMaterialsAndWorks";
	LongDesc.WarehouseFieldName = "TS.Warehouse";
	DetailsList1.Add(LongDesc);
	LongDesc = DescriptionOfDeliveryOrder();
	LongDesc.Name = "GoodsShipmentFromStorage";
	DetailsList1.Add(LongDesc);
	
	LongDesc = DescriptionOfDeliveryOrder();
	LongDesc.Name = "TransferOfGoodsToBailee";
	LongDesc.WarehouseFieldName = "TS.Warehouse";
	DetailsList1.Add(LongDesc);
	
	LongDesc = DescriptionOfDeliveryOrder();
	LongDesc.Name = "GoodsReceiptForStorage";
	LongDesc.WarehouseFieldName = "TS.Warehouse";
	LongDesc.FieldNameSeries = "VALUE(Catalog.ItemsBatches.EmptyRef)";
	DetailsList1.Add(LongDesc);
	
	
	LongDesc = DescriptionOfDeliveryOrder();
	LongDesc.Name = "MaterialProviderOrder2_5";
	LongDesc.ThisIsOrder = True;
	LongDesc.TSName = "ManufacturedProduct";
	LongDesc.WarehouseFieldName = "TS.Warehouse";
	LongDesc.NameOfDestinationField = "Header.Purpose";
	DetailsList1.Add(LongDesc);
	LongDesc = DescriptionOfDeliveryOrder();
	LongDesc.Name = "SalesOrder";
	LongDesc.ThisIsOrder = True;
	LongDesc.WarehouseFieldName = "TS.Warehouse";
	LongDesc.NameOfDestinationField =
	"CASE
	|		WHEN TS.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
	|			AND TS.WithAssignment
	|			AND ISNULL(Header.Purpose.RecordsInWarehouseRegisters, FALSE)
	|			THEN Header.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END";
	DetailsList1.Add(LongDesc);
	
	LongDesc = DescriptionOfDeliveryOrder();
	LongDesc.Name = "RequestForReturnOfGoodsFromCustomer";
	LongDesc.ThisIsOrder = True;
	LongDesc.TSName = "SubstituteGoods";
	LongDesc.NameOfDestinationField = "Header.Purpose";
	DetailsList1.Add(LongDesc);
	
	LongDesc = DescriptionOfDeliveryOrder();
	LongDesc.Name = "TransferOrder";
	LongDesc.ThisIsOrder = True;
	LongDesc.WarehouseFieldName = "Header.SourceWarehouse";
	LongDesc.FieldNameRecipientSender = "DestinationWarehouse";
	DetailsList1.Add(LongDesc);
	
	LongDesc = DescriptionOfDeliveryOrder();
	LongDesc.Name = "InventoryTransfer";
	LongDesc.WarehouseFieldName = "Header.SourceWarehouse";
	LongDesc.FieldNameRecipientSender = "DestinationWarehouse";
	LongDesc.NameOfDestinationField = "TS.AssignmentSender";
	DetailsList1.Add(LongDesc);
	
	LongDesc = DescriptionOfDeliveryOrder();
	LongDesc.Name = "CustomerInvoice";
	LongDesc.WarehouseFieldName = "TS.Warehouse";
	DetailsList1.Add(LongDesc);
	
	LongDesc = DescriptionOfDeliveryOrder();
	LongDesc.Name = "ReturnOfGoodsToVendor";
	DetailsList1.Add(LongDesc);
	
	LongDesc = DescriptionOfDeliveryOrder();
	LongDesc.Name = "PurchaseOrder";
	LongDesc.ThisIsOrder = True;
	LongDesc.WarehouseFieldName = "TS.Warehouse";
	LongDesc.FieldNameSeries = "VALUE(Catalog.ItemsBatches.EmptyRef)";
	DetailsList1.Add(LongDesc);
	LongDesc = DescriptionOfDeliveryOrder();
	
	LongDesc.Name = "VendorInvoice";
	LongDesc.WarehouseFieldName = "TS.Warehouse";
	LongDesc.FieldNameSeries = "VALUE(Catalog.ItemsBatches.EmptyRef)";
	DetailsList1.Add(LongDesc);
	
	Return DetailsList1;
	
EndFunction

// Returns the time without a date.
//
// Parameters:
//  DateTime	 - Date	 - date.
// 
// Returns:
//  Date - time without date.
//
Function TimeWithoutDate(DateTime) Export
	Return Date(1,1,1,Hour(DateTime),Minute(DateTime),Second(DateTime));
EndFunction

// Returns a string with the delivery time in the form " %Timestamp% - %Timestamp%".
//
// Parameters:
//  TimeFrom	 - Date	 - start time;
//  TimeTo	 - Date	 - end time.
// 
// Returns:
//  String - presentation of the delivery time in the format "%Time% - %Time%".
//
Function PresentationOfDeliveryTime(TimeFrom, TimeTo) Export
	
	If ValueIsFilled(TimeTo) Then
		Text = NStr("vi = '%TimeFrom% - %TimeTo%';
					|ru = '%TimeFrom% - %TimeTo%';
					|en = '%TimeFrom% - %TimeTo%'; fa = '%TimeFrom% - %TimeTo%';
					|it = '%TimeFrom% - %TimeTo%';
					|pl = '%TimeFrom% - %TimeTo%';
					|tr = '%TimeFrom% - %TimeTo%'");
		Text = StrReplace(Text, "%TimeFrom%", Format(TimeFrom, "DF=HH:mm"));
		Return StrReplace(Text, "%TimeTo%", Format(TimeTo, "DF=HH:mm"));
	Else
		Return Format(TimeFrom, "DF=HH:mm");
	EndIf;
	
EndFunction

// Returns a view of the recipient for delivery
//  . if the delivery is by carrier, the view is " %Carrier% (%Consignee%)".
//
// Parameters:
//  RecipientSender - CatalogRef.Partners - a sender / receiver of the cargo;
//  Carrier - CatalogRef.Partners - carrier;
//  DeliveryKind- EnumRef.DeliveryKinds - type of delivery.
// 
// Returns:
//  String - representation of the recipient / sender of the cargo.
//
Function PresentationOfSenderSRecipient(RecipientSender, Carrier, DeliveryKind) Export
	
	If ValueIsFilled(Carrier) Then
		
		If DeliveryKind = PredefinedValue("Enum.DeliveryKinds.FromWarehouse") Then
			Text = NStr("vi = '%Carrier% (cho %RecipientSender%)';
						|ru = '%Carrier% (для %RecipientSender%)';
						|en = '%Carrier% (for %RecipientSender%)'; fa = '%Carrier% (for %RecipientSender%)';
						|it = '%Carrier% (per %RecipientSender%)';
						|pl = '%Carrier% (dla %RecipientSender%)';
						|tr = '%Carrier% (%RecipientSender% için)'");
		Else
			Text = NStr("vi = '%Carrier% (từ %RecipientSender%)';
						|ru = '%Carrier% (от %RecipientSender%)';
						|en = '%Carrier% (from %RecipientSender%)'; fa = '%Carrier% (from %RecipientSender%)';
						|it = '%Carrier% (di %RecipientSender%)';
						|pl = '%Carrier% (od %RecipientSender%)';
						|tr = '%Carrier% (%RecipientSender% itibaren )'");
		EndIf;
		
		Text = StrReplace(Text, "%RecipientSender%", String(RecipientSender));
		Return StrReplace(Text, "%Carrier%", String(Carrier));
		
	Else
		
		Return String(RecipientSender);
		
	EndIf;
	
EndFunction

// Names of Attributes of delivery addresses.
// 
// Parameters:
//  NameOfDetailsOfDeliveryAddress - String - Name Of The Details Of The Delivery Address
// 
// Returns:
//  Structure -- Names of Attributes of delivery addresses::
// * NameOfDetailsOfDeliveryAddress - String -
// * AttributeNameOfDeliveryAddressFieldValues - String -
// * NameOfAttributeOfDeliveryAddressValue - String -
//
Function NamesOfDetailsOfDeliveryAddresses(NameOfDetailsOfDeliveryAddress = "") Export
	
	NamesOfDetailsOfDeliveryAddresses = New Structure();
	
	If IsBlankString(NameOfDetailsOfDeliveryAddress) Then
		NamesOfDetailsOfDeliveryAddresses.Insert("NameOfDetailsOfDeliveryAddress", "");
		NamesOfDetailsOfDeliveryAddresses.Insert("AttributeNameOfDeliveryAddressFieldValues", "");
		NamesOfDetailsOfDeliveryAddresses.Insert("NameOfAttributeOfDeliveryAddressValue", "");
	ElsIf NameOfDetailsOfDeliveryAddress = "DeliveryAddressOfCarrier" Then
		NamesOfDetailsOfDeliveryAddresses.Insert("NameOfDetailsOfDeliveryAddress", "DeliveryAddressOfCarrier");
		NamesOfDetailsOfDeliveryAddresses.Insert("AttributeNameOfDeliveryAddressFieldValues", "DeliveryAddressOfCarrierFieldValues");
		NamesOfDetailsOfDeliveryAddresses.Insert("NameOfAttributeOfDeliveryAddressValue", "DeliveryAddressOfCarrierValue");
	ElsIf NameOfDetailsOfDeliveryAddress = "DeliveryAddress" Then 
		NamesOfDetailsOfDeliveryAddresses.Insert("NameOfDetailsOfDeliveryAddress", "DeliveryAddress");
		NamesOfDetailsOfDeliveryAddresses.Insert("AttributeNameOfDeliveryAddressFieldValues", "DeliveryAddressFieldValues");
		NamesOfDetailsOfDeliveryAddresses.Insert("NameOfAttributeOfDeliveryAddressValue", "DeliveryAddressValue");
	ElsIf NameOfDetailsOfDeliveryAddress = "LoadingAddress" Then 
		NamesOfDetailsOfDeliveryAddresses.Insert("NameOfDetailsOfDeliveryAddress", "LoadingAddress");
		NamesOfDetailsOfDeliveryAddresses.Insert("AttributeNameOfDeliveryAddressFieldValues", "LoadingAddressFieldValues");
		NamesOfDetailsOfDeliveryAddresses.Insert("NameOfAttributeOfDeliveryAddressValue", "LoadingAddressValue");
	ElsIf NameOfDetailsOfDeliveryAddress = "Address" Then 
		NamesOfDetailsOfDeliveryAddresses.Insert("NameOfDetailsOfDeliveryAddress", "Address");
		NamesOfDetailsOfDeliveryAddresses.Insert("AttributeNameOfDeliveryAddressFieldValues", "FieldValueAddress");
		NamesOfDetailsOfDeliveryAddresses.Insert("NameOfAttributeOfDeliveryAddressValue", "AddressValue");
	EndIf;
	
	Return NamesOfDetailsOfDeliveryAddresses;
	
EndFunction

// Checks whether the additional delivery Information field has been changed by the user.
//
// Parameters:
//	FormItems - FormAllItems - elements of the form in which the check is performed;
//	DocObject - DocumentObject - Document for verification:
//		* AdditionalDeliveryInformation - String -
//
// Returns:
//	Boolean - True - the value of the "Additional Delivery Information" field has been changed.
//
Function AdditionalInfoChangedByUser(FormItems, DocObject) Export
	
	AdditionalInfoChanged = False;
	AddlInfo = DocObject.AdditionalDeliveryInformation;
	
	If Not ValueIsFilled(AddlInfo) Then
		
		Return False;
		
	ElsIf FormItems.Find("SupplierSAddress") <> Undefined Then
		
		AdditionalInfoChanged = Not AdditionalInfoIsInItemSelectionList(FormItems.SupplierSAddress, AddlInfo);
		
	ElsIf FormItems.Find("ItemAddress") <> Undefined Then
		
		AdditionalInfoChanged = Not AdditionalInfoIsInItemSelectionList(FormItems.ItemAddress, AddlInfo);
		
	ElsIf FormItems.Find("DeliveryAddress") <> Undefined Then
		
		AdditionalInfoChanged = Not AdditionalInfoIsInItemSelectionList(FormItems.DeliveryAddress, AddlInfo);
		
	Else
		
		AdditionalInfoChanged = Not AdditionalInfoIsInItemSelectionList(FormItems.RecipientDeliveryAddress, AddlInfo);
		If FormItems.Find("RecipientDeliveryAddress1") <> Undefined
			And Not AdditionalInfoChanged Then
			AdditionalInfoChanged = Not AdditionalInfoIsInItemSelectionList(FormItems.RecipientDeliveryAddress1, AddlInfo);
		EndIf;
	EndIf;
		
	If FormItems.Find("DeliveryAddressOfCarrier") <> Undefined
		And Not AdditionalInfoChanged Then
		AdditionalInfoChanged = Not AdditionalInfoIsInItemSelectionList(FormItems.DeliveryAddressOfCarrier, AddlInfo);
	EndIf;
	
	Return AdditionalInfoChanged;
	
EndFunction

// Function - delivery Methods to the client with our participation
//
// Parameters:
//  UseTransportationJobsForDeliveryAccountingByCarriers	 - Boolean - the value of the functional option use transport task for accounting for delivery by Carriers.
// 
// Returns:
//  Array of EnumRef.TransportMethods
//
Function DeliveryMethodsToCustomerWithOurParticipation(UseTransportationJobsForDeliveryAccountingByCarriers) Export 
	
	TransportMethods = New Array; // Array of EnumRef.TransportMethods
	
	TransportMethods.Add(PredefinedValue("Enum.TransportMethods.ToCustomer"));
	TransportMethods.Add(PredefinedValue("Enum.TransportMethods.ByCarrierToAddress"));
	TransportMethods.Add(PredefinedValue("Enum.TransportMethods.ToCustomerIsDefinedByTransportationCompany"));
	
	If UseTransportationJobsForDeliveryAccountingByCarriers Then
		TransportMethods.Add(PredefinedValue("Enum.TransportMethods.ByCarrier"));
	EndIf;
	
	Return TransportMethods;
	
EndFunction

// Calculates the under-load or over-load of the vehicle by weight and volume,
//	displays the result in the label and displays the image corresponding to the fullness of the transport.
//
// Parameters:
//  Form - See DataProcessor.WorkplaceOfDeliveryOfficer.Form.Form
//  	  - See DataProcessor.WorkplaceOfDeliveryOfficer.Form.RoutePointReferences
//  	  - See Document.TransportationJob.Form.DocumentForm  
//  DataWeightVolume  - FormDataCollectionItem, Undefined - data that is used for the calculation.
//
Procedure DisplayUnderloadOverload(Form, DataWeightVolume) Export
	
	BoldFont = Form.BoldFont; // StyleFonts
	ColorGreen = Form.ColorGreen; // StyleColors 
	ColorRed = Form.ColorRed; // StyleColors
	
	Items = Form.Items;
	If DataWeightVolume <> Undefined Then
		
		UnderloadWeight = Round(DataWeightVolume.CarryingCapacityInUserUnit - DataWeightVolume.Weight);
		UnderloadedVolume = Round(DataWeightVolume.CapacityInUserUnits - DataWeightVolume.VolumeM3);
		
	EndIf;
	
	Template = NStr("vi = '%Count% %UnitOfMeasure%';
					|ru = '%Count% %UnitOfMeasure%';
					|en = '%Count% %UnitOfMeasure%'; fa = '%Count% %UnitOfMeasure%';
					|it = '%Count% %UnitOfMeasure%';
					|pl = '%Count% %UnitOfMeasure%';
					|tr = '%Count% %UnitOfMeasure%'");
	
	If DataWeightVolume = Undefined
	 Or DataWeightVolume.CarryingCapacityInUserUnit = 0 Then
		
		Form.LabelUnderloadWeight = New FormattedString("");
		Items.DecorationWeight.Picture = New Picture;
		
	ElsIf UnderloadWeight >= 0 Then
		
		Text = StrReplace(Template, "%Count%", String(UnderloadWeight));
		Text = StrReplace(Text, "%UnitOfMeasure%", String(Form.UnitOfMeasureForWeight));
		
		Form.LabelUnderloadWeight = New FormattedString(Text, BoldFont, ColorGreen);
		
		OccupancyWeight = DataWeightVolume.Weight / DataWeightVolume.CarryingCapacityInUserUnit * 100;
		If OccupancyWeight > 95 Then
			Items.DecorationWeight.Picture = PictureLib.Status100Percent;
		ElsIf OccupancyWeight > 45 Then
			Items.DecorationWeight.Picture = PictureLib.Status66Percent;
		ElsIf OccupancyWeight > 5 Then
			Items.DecorationWeight.Picture = PictureLib.Status33Percent;
		Else
			Items.DecorationWeight.Picture = PictureLib.Status0Percent;
		EndIf;
		
	Else
		
		Text = StrReplace(Template, "%Count%", String(-UnderloadWeight));
		Text = StrReplace(Text, "%UnitOfMeasure%", String(Form.UnitOfMeasureForWeight));
		Form.LabelUnderloadWeight = New FormattedString(Text, BoldFont, ColorRed);
		Items.DecorationWeight.Picture = PictureLib.Stop;
		
	EndIf;
	
	If DataWeightVolume = Undefined
	 Or DataWeightVolume.CapacityInUserUnits = 0 Then
		
		Form.LabelUnderLoadVolume = New FormattedString("");
		Items.DecorationVolume.Picture = New Picture;
		
	ElsIf UnderloadedVolume >= 0 Then
		
		Text = StrReplace(Template, "%Count%", String(UnderloadedVolume));
		Text = StrReplace(Text, "%UnitOfMeasure%", String(Form.UnitOfMeasureForVolume));
		Form.LabelUnderLoadVolume = New FormattedString(Text, BoldFont, ColorGreen);
		OccupancyVolume = DataWeightVolume.VolumeM3 / DataWeightVolume.CapacityInUserUnits * 100;
		If OccupancyVolume > 95 Then
			Items.DecorationVolume.Picture = PictureLib.Status100Percent;
		ElsIf OccupancyVolume > 45 Then
			Items.DecorationVolume.Picture = PictureLib.Status66Percent;
		ElsIf OccupancyVolume > 5 Then
			Items.DecorationVolume.Picture = PictureLib.Status33Percent;
		Else
			Items.DecorationVolume.Picture = PictureLib.Status0Percent;
		EndIf;
		
	Else
		
		Text = StrReplace(Template, "%Count%", String(-UnderloadedVolume)); 
		Text = StrReplace(Text, "%UnitOfMeasure%", String(Form.UnitOfMeasureForVolume));
		Form.LabelUnderLoadVolume = New FormattedString(Text, BoldFont, ColorRed);
		Items.DecorationVolume.Picture = PictureLib.Stop;
		
	EndIf;
	
EndProcedure

// Calculates whether delivery is required for the transmitted method.
//
// Parameters:
//  DeliveryMethod	- EnumRef.TransportMethods - verified delivery method.
//	UseTransportationJobsForDeliveryAccountingByCarriers - Boolean - value of the functional option use_task_transport_account_delivery by Carriers
// Returns:
//  Boolean - delivery required or not.
//
Function ShippingIsUsed(Val DeliveryMethod, Val UseTransportationJobsForDeliveryAccountingByCarriers = False) Export
	
	TransportMethods = ShippingMethodsUsed(UseTransportationJobsForDeliveryAccountingByCarriers);
	
	Return TransportMethods.Find(DeliveryMethod) <> Undefined;
	
EndFunction

// Delivery methods that can be used
// 
// Parameters:
//  UseTransportationJobsForDeliveryAccountingByCarriers - Boolean - the value of the functional option use transport task for accounting for delivery by Carriers.
// 
// Returns:
//   Array of EnumRef.TransportMethods 
//
Function ShippingMethodsUsed(Val UseTransportationJobsForDeliveryAccountingByCarriers = False) Export
	
	TransportMethods = New Array; // Array of EnumRef.TransportMethods
	
	If UseTransportationJobsForDeliveryAccountingByCarriers Then
		TransportMethods.Add(PredefinedValue("Enum.TransportMethods.ByCarrierToOurWarehouse"));
	EndIf;
	
	TransportMethods.Add(PredefinedValue("Enum.TransportMethods.ToCustomer"));
	TransportMethods.Add(PredefinedValue("Enum.TransportMethods.ToCustomerIsDefinedByTransportationCompany"));
	TransportMethods.Add(PredefinedValue("Enum.TransportMethods.ByCarrier"));
	TransportMethods.Add(PredefinedValue("Enum.TransportMethods.ByCarrierToAddress"));
	TransportMethods.Add(PredefinedValue("Enum.TransportMethods.OurOwnDeliveryFromSenderAddress"));
	TransportMethods.Add(PredefinedValue("Enum.TransportMethods.ByCarrierToTransferPoint"));
	TransportMethods.Add(PredefinedValue("Enum.TransportMethods.FromSenderDeterminedByDeliveryService"));
	TransportMethods.Add(PredefinedValue("Enum.TransportMethods.ByCarrierToTransferPoint"));
	
	Return TransportMethods;
	
EndFunction

// Returns an empty structure of order parameters.
// 
// Returns:
//  Structure - Order Parameters:
// * DeliveryMethod - EnumRef.TransportMethods - 
// * DeliveryAddress - String - 
// * DeliveryAddressValue - String - 
// * DeliveryAddressFieldValues - String - 
// * DeliveryMethodObject_ - EnumRef.TransportMethods - 
// * DeliveryZone - CatalogRef.DeliveryZones - 
// * DeliveryTimeFrom - Date - 
// * DeliveryTimeTo - Date - 
// * CarrierPartner - CatalogRef.Partners - 
// * DeliveryAddressOfCarrier - String - 
// * DeliveryAddressOfCarrierValue - String - 
// * DeliveryAddressOfCarrierFieldValues - String - 
// * AdditionalDeliveryInformation - String - 
// * SpecialTransportationConditions - Boolean - 
// * SpecialTransportationConditionsDescription - String - 
// * Courier - CatalogRef.Persons - 
// * Ref - Undefined, DocumentRef, CatalogRef - Link to the order
// * Date - Date - 
// * Partner - CatalogRef.Partners - 
// * Counterparty - CatalogRef.Counterparties - 
// * GoodsRecipient - CatalogRef.Counterparties - 
// * Terms - CatalogRef.TermsOfSale - 
// * Contract - CatalogRef.CounterpartyContracts - 
// * OrderSales - Boolean - 
//
Function OrderParameters() Export
	
	Parameters = GetEmptyStructureOfDeliveryDetails();
	
	Parameters.Insert("Ref", Undefined);
	Parameters.Insert("Date", Date(1,1,1));
	Parameters.Insert("Partner", PredefinedValue("Catalog.Partners.EmptyRef"));
	Parameters.Insert("Counterparty", PredefinedValue("Catalog.Counterparties.EmptyRef"));
	Parameters.Insert("GoodsRecipient", PredefinedValue("Catalog.Counterparties.EmptyRef"));
	Parameters.Insert("Terms", PredefinedValue("Catalog.TermsOfSale.EmptyRef"));
	Parameters.Insert("Contract", PredefinedValue("Catalog.CounterpartyContracts.EmptyRef"));
	Parameters.Insert("OrderSales", False);
	
	Return Parameters;
	
EndFunction

#EndRegion

#EndRegion

#Region Internal

// New Delivery settings.
// 
// Returns:
//  Structure - New Delivery Settings:
// * DeliveryPlanning - EnumRef.DeliveryPlanningKinds -
// * AllowChangingTypeOfDeliveryPlanning - Boolean - 
// * DeliverySpecificationMethod - EnumRef.DeliverySpecificationMethods -
// * AllowChangingDeliveryIndicationMethod - Boolean - 
// * DeliveryMethod - EnumRef.TransportMethods25 - 
// * ShippingMethodsUsed - Array of EnumRef.TransportMethods25 - should not be used together with the excluded delivery capability
// * ExcludedDeliveryMethods - Array of EnumRef.TransportMethods25 - Should not be used in conjunction with the delivery capability used
// * Partner - CatalogRef.Partners - 
// * DeliveryPoint - CatalogRef.DeliveryPoints - 
// * DeliveryZone - CatalogRef.DeliveryZones - 
// * DeliveryToCarrier - Boolean - 
// * Carrier - CatalogRef.Partners - 
// * CarrierDeliveryPoint - CatalogRef.DeliveryPoints - 
// * CarrierSDeliveryArea - CatalogRef.DeliveryZones - 
// * DeliveryTimeFrom - Date, TypeDescription - 
// * DeliveryTimeTo - Date, TypeDescription - 
// * AdditionalDeliveryInformation - String - 
// * SpecialTransportationConditions - Boolean - 
// * SpecialTransportationConditionsDescription - String - 
// * Courier - CatalogRef.Persons -
// * SingleShipmentDateIsUsed - Boolean - if True, then the column of shipment dates is hidden in the line-by-line delivery.
// * Goods - Array of See NewDeliveryLineData
// * Warehouses - Array of See NewDeliveryWarehouseRowData
// 
Function NewDeliverySettings() Export
	
	TypeTime = New TypeDescription("Date",,, New DateQualifiers(DateFractions.Time));
	StringType0 = "";
	ShippingMethodsUsed = New Array; // Array of EnumRef.TransportMethods25
	ExcludedDeliveryMethods = New Array; // Array of EnumRef.TransportMethods25
	
	Parameters = New Structure;
	
	Parameters.Insert("DeliveryPlanning", PredefinedValue("Enum.DeliveryPlanningKinds.ByCurrentDocument"));
	Parameters.Insert("AllowChangingTypeOfDeliveryPlanning", True);
	Parameters.Insert("DeliverySpecificationMethod", PredefinedValue("Enum.DeliverySpecificationMethods.ForWholeDocument"));
	Parameters.Insert("AllowChangingDeliveryIndicationMethod", True);
	Parameters.Insert("DeliveryMethod", PredefinedValue("Enum.TransportMethods25.EmptyRef"));
	Parameters.Insert("ShippingMethodsUsed", ShippingMethodsUsed);
	Parameters.Insert("ExcludedDeliveryMethods", ExcludedDeliveryMethods);
	Parameters.Insert("Partner", PredefinedValue("Catalog.Partners.EmptyRef"));
	Parameters.Insert("DeliveryPoint", PredefinedValue("Catalog.DeliveryPoints.EmptyRef"));
	Parameters.Insert("DeliveryZone", PredefinedValue("Catalog.DeliveryZones.EmptyRef"));
	Parameters.Insert("DeliveryToCarrier", False);
	Parameters.Insert("Carrier", PredefinedValue("Catalog.Partners.EmptyRef"));
	Parameters.Insert("CarrierDeliveryPoint", PredefinedValue("Catalog.DeliveryPoints.EmptyRef"));
	Parameters.Insert("CarrierSDeliveryArea", PredefinedValue("Catalog.DeliveryZones.EmptyRef"));
	Parameters.Insert("DeliveryTimeFrom", TypeTime);
	Parameters.Insert("DeliveryTimeTo", TypeTime);
	Parameters.Insert("AdditionalDeliveryInformation", StringType0);
	Parameters.Insert("SpecialTransportationConditions", False);
	Parameters.Insert("SpecialTransportationConditionsDescription", StringType0);
	Parameters.Insert("Courier", PredefinedValue("Catalog.Persons.EmptyRef"));
	Parameters.Insert("SingleShipmentDateIsUsed", True);
	
	Goods = New Array; // Array of See NewDeliveryLineData
	Parameters.Insert("Goods", Goods);
	
	Warehouses = New Array; // Array of See NewDeliveryWarehouseRowData
	Parameters.Insert("Warehouses", Warehouses);
	
	Return Parameters;
	
EndFunction

// New delivery line data.
// 
// Returns:
//  Structure - New Delivery Line Data:
// * DocumentRowNumber - Number - non-negative, length 9
// * RowCode - Number - non-negative, length 10
// * Products - CatalogRef.Products - 
// * Characteristic - CatalogRef.ItemsCharacteristics - 
// * ItemVariantsAreUsed - Boolean - 
// * Series - CatalogRef.ItemsBatches -
// * BatchesIndicationStatus - Number - non-negative, length 2, precision 0y 
// * NumberOfPackages - Number - non-negative, length 15, accuracy 3
// * Package - CatalogRef.PackagesAndUnitsOfMeasure -
// * DeliveryMethod - EnumRef.TransportMethods25- 
// * DeliveryPoint - CatalogRef.DeliveryPoints - 
// * DeliveryZone - CatalogRef.DeliveryZones - 
// * DeliveryToCarrier - Boolean - 
// * Carrier - CatalogRef.Partners - 
// * CarrierDeliveryPoint - CatalogRef.DeliveryPoints - 
// * CarrierSDeliveryArea - CatalogRef.DeliveryZones -
// * DeliveryTimeFrom - Date - Delivery time
// * DeliveryTimeTo - Date - Delivery time 
// * AdditionalDeliveryInformation - String - 
// * SpecialTransportationConditions - Boolean - 
// * SpecialTransportationConditionsDescription - String -
// * DateOfShipment - Date - 
// 
Function NewDeliveryLineData() Export
	
	StringType0 = "";
	
	Parameters = New Structure;
	
	Parameters.Insert("DocumentRowNumber", 0);
	Parameters.Insert("RowCode", 0);
	Parameters.Insert("Products", PredefinedValue("Catalog.Products.EmptyRef"));
	Parameters.Insert("Characteristic", PredefinedValue("Catalog.ItemsCharacteristics.EmptyRef"));
	Parameters.Insert("ItemVariantsAreUsed", False);
	Parameters.Insert("Series", PredefinedValue("Catalog.ItemsBatches.EmptyRef"));
	Parameters.Insert("BatchesIndicationStatus", 0);
	Parameters.Insert("NumberOfPackages", 0);
	Parameters.Insert("Package", PredefinedValue("Catalog.PackagesAndUnitsOfMeasure.EmptyRef"));
	Parameters.Insert("DeliveryMethod", PredefinedValue("Enum.TransportMethods25.EmptyRef"));
	Parameters.Insert("DeliveryPoint", PredefinedValue("Catalog.DeliveryPoints.EmptyRef"));
	Parameters.Insert("DeliveryZone", PredefinedValue("Catalog.DeliveryZones.EmptyRef"));
	Parameters.Insert("DeliveryToCarrier", False);
	Parameters.Insert("Carrier", PredefinedValue("Catalog.Partners.EmptyRef"));
	Parameters.Insert("CarrierDeliveryPoint", PredefinedValue("Catalog.DeliveryPoints.EmptyRef"));
	Parameters.Insert("CarrierSDeliveryArea", PredefinedValue("Catalog.DeliveryZones.EmptyRef"));
	Parameters.Insert("DeliveryTimeFrom", Date(1, 1 , 1));
	Parameters.Insert("DeliveryTimeTo", Date(1, 1 , 1));
	Parameters.Insert("AdditionalDeliveryInformation", StringType0);
	Parameters.Insert("SpecialTransportationConditions", False);
	Parameters.Insert("SpecialTransportationConditionsDescription", StringType0);
	Parameters.Insert("DateOfShipment", Date(1, 1 , 1));
	
	Return Parameters;
	
EndFunction

// New Delivery warehouse row data.
// 
// Returns:
//  Structure - New Delivery warehouse settings:
// * Warehouse - CatalogRef.Warehouses - 
// * WarehousePoint - CatalogRef.DeliveryPoints - 
// * AreaOfWarehouse - CatalogRef.DeliveryZones -
// 
Function NewDeliveryWarehouseRowData() Export
	
	Parameters = New Structure;
	
	Parameters.Insert("Warehouse", PredefinedValue("Catalog.Warehouses.EmptyRef"));
	Parameters.Insert("WarehousePoint", PredefinedValue("Catalog.DeliveryPoints.EmptyRef"));
	Parameters.Insert("AreaOfWarehouse", PredefinedValue("Catalog.DeliveryZones.EmptyRef"));
	
	Return Parameters;
	
EndFunction

// Describes the basic default values for delivery parameters
//
// Returns:
//  See NewDeliverySettings
//
Function DefaultDeliverySettings() Export
	
	Parameters = NewDeliverySettings();
	Parameters.DeliveryPlanning = PredefinedValue("Enum.DeliveryPlanningKinds.ByCurrentDocument");
	Parameters.DeliverySpecificationMethod = PredefinedValue("Enum.DeliverySpecificationMethods.ForWholeDocument");
	Parameters.DeliveryMethod = PredefinedValue("Enum.TransportMethods25.OwnDelivery");
	Parameters.DeliveryToCarrier = False;
	
	Return Parameters;
	
EndFunction

// Used in delivery point lists to hide or show archive points
// 
// Parameters:
//  Form - See Catalog.DeliveryPoints.Form.ListForm
//        - See Catalog.DeliveryPoints.Form.ChoiceForm
//        - See Catalog.DeliveryPoints.Form.OwnerDeliveryPoints
//
Procedure ChangeSelectionOfCurrentPoints(Form) Export
	
	List = Form.List;
	
	ParameterName = "HideUnused";
	ParameterValue = List.Parameters.FindParameterValue(New DataCompositionParameter(ParameterName));
	
	If ParameterValue = Undefined Then
		
		Return;
		
	EndIf;
	
	RequiredToHide = Not ParameterValue.Use;
	CommonClientServer.SetDynamicListParameter(List, ParameterName, True, RequiredToHide);
	
	NameOfCommandButton = "FormShouldShowUnused";
	
	If RequiredToHide Then
		
		Picture = PictureLib.FlagNotSpecified;
		
	Else
		
		Picture = PictureLib.FlagSpecified;
		
	EndIf;
	
	CommonClientServer.SetFormItemProperty(Form.Items, NameOfCommandButton, "Picture", Picture);
	
EndProcedure

// Parameters:
//  CheckResult - See GoodsDelivery.CheckPossibilityOfSwitchingToDelivery25
// 
// Returns:
//  String -
//
Function TextOfVerificationOfPossibilityOfSwitchingToDelivery25(CheckResult) Export
	
	If CheckResult.ThereAreLeftoversToBeShipped Then
		
		WarningText = NStr("ru = 'Необходимо отгрузить все товары по распоряжениям с запланированной доставкой со складов с настройкой ""Собирать товары в порядке доставки"".';
							|vi = 'Ship all goods under references with scheduled delivery from warehouses with the ""Pick goods according to the delivery procedure"" setting.';
							|en = 'Ship all goods under references with scheduled delivery from warehouses with the ""Pick goods according to the delivery procedure"" setting.'; fa = 'Ship all goods under references with scheduled delivery from warehouses with the ""Pick goods according to the delivery procedure"" setting.';
							|it = 'Ship all goods under references with scheduled delivery from warehouses with the ""Pick goods according to the delivery procedure"" setting.';
							|pl = 'Ship all goods under references with scheduled delivery from warehouses with the ""Pick goods according to the delivery procedure"" setting.';
							|tr = '""Malları teslimat sırasına göre topla"" ayarına sahip ambarlardan, teslimatı planlanmış talimatlara göre tüm malların sevk edilmesi gerekir.'");
		
	ElsIf CheckResult.ThereAreWarehousesForKitsAfterDelivery Then
		
		WarningText = NStr("ru = 'Используются ордерные склады с настройкой ""Собирать товары в порядке доставки"", сборка по данным рейса не поддерживается при порядке оформления ордеров ""Сначала заказы и накладные, затем ордера"".';
							|vi = 'Warehouse management with the ""Pick goods according to the delivery procedure"" setting is used. Picking based on the trip data is not supported if the ""Orders and invoices first, then goods issues"" option is used.';
							|en = 'Warehouse management with the ""Pick goods according to the delivery procedure"" setting is used. Picking based on the trip data is not supported if the ""Orders and invoices first, then goods issues"" option is used.'; fa = 'Warehouse management with the ""Pick goods according to the delivery procedure"" setting is used. Picking based on the trip data is not supported if the ""Orders and invoices first, then goods issues"" option is used.';
							|it = 'Warehouse management with the ""Pick goods according to the delivery procedure"" setting is used. Picking based on the trip data is not supported if the ""Orders and invoices first, then goods issues"" option is used.';
							|pl = 'Warehouse management with the ""Pick goods according to the delivery procedure"" setting is used. Picking based on the trip data is not supported if the ""Orders and invoices first, then goods issues"" option is used.';
							|tr = '""Malları teslimat sırasına göre topla"" ayarına sahip sipariş ambarları kullanılıyor, ""Önce siparişler ve irsaliyeler, ardından emirler"" sipariş oluşturma düzeninde sefer verilerine göre toplama desteklenmiyor.'");
		
	Else
		
		WarningText = "";
		
	EndIf;
	
	Return WarningText;
	
EndFunction

// Returns:
//  String -
//
Function TextForCheckingActiveSessions() Export
	
	MessageText = NStr("ru = 'Для перехода на доставку 2.5 необходимо закрыть все сеансы, кроме текущего.';
						|vi = 'To migrate to delivery 2.5, close all sessions except for the current one.';
						|en = 'To migrate to delivery 2.5, close all sessions except for the current one.'; fa = 'To migrate to delivery 2.5, close all sessions except for the current one.';
						|it = 'To migrate to delivery 2.5, close all sessions except for the current one.';
						|pl = 'To migrate to delivery 2.5, close all sessions except for the current one.';
						|tr = 'Teslimat 2.5''e geçiş için, mevcut oturum hariç tüm oturumların kapatılması gerekir.'");
	Return MessageText;
	
EndFunction

// Returns:
//  String -
//
Function ConditionalAppearanceTextIsNotUsedWeightVolume() Export
	
	TextNotUsed = "---";
	
	Return TextNotUsed;
	
EndFunction

#EndRegion

#Region Private

// Fills in the selection list for the delivery time input field.
//
// Parameters:
//	FormInputField - FormField, FormFieldExtensionForATextBox -
//	               - Array of FormField, FormFieldExtensionForATextBox - the input box delivery time
//	Interval - Number - the time interval (seconds) between the values of the selection list (by default, 1 hour).
//
Procedure FillTimeFieldSelectionList(FormInputField, Interval = 3600) Export
	
	If TypeOf(FormInputField) = Type("FormField") Then
		FormItems = New Array; // Array of FormField
		FormItems.Add(FormInputField);
	ElsIf TypeOf(FormInputField) = Type("Array") Then
		FormItems = FormInputField;
	Else
		Return;
	EndIf;
	
	ChoiceList = New ValueList; // ValueList of Date
	
	WorkdayBeginning = '00010101000000';
	WorkdayEnd = '00010101235959';
	
	ListTime = WorkdayBeginning;
	
	While ListTime <= WorkdayEnd Do
		
		If Not ValueIsFilled(ListTime) Then
			ChoiceList.Add(ListTime + 1, "00:00"); // non-empty value
		Else
			ChoiceList.Add(ListTime, Format(ListTime,"DF=HH:mm"));
		EndIf;
		
		ListTime = ListTime + Interval;
		
	EndDo;
	
	For Each FormItem In FormItems Do
		
		FormItem.ChoiceList.Clear();
		For Each SelectionListItem In ChoiceList Do
			FormItem.ChoiceList.Add(SelectionListItem.Value, SelectionListItem.Presentation);
		EndDo;
		
	EndDo;
	
EndProcedure

#Region Delivery20

// Returns:
//  Structure - Description Of The Delivery Order:
// * Name - String -
// * ThisIsOrder - Boolean - 
// * TSName - String - 
// * WarehouseFieldName - String - 
// * FieldNameRecipientSender - String - 
// * NameOfDestinationField - String - 
// * FieldNameSeries - String - 
//
Function DescriptionOfDeliveryOrder()
	
	LongDesc = New Structure;
	LongDesc.Insert("Name", "");
	LongDesc.Insert("ThisIsOrder", False);
	LongDesc.Insert("TSName", "Goods");
	LongDesc.Insert("WarehouseFieldName", "Header.Warehouse");
	LongDesc.Insert("FieldNameRecipientSender", "Partner");
	LongDesc.Insert("NameOfDestinationField", "TS.Purpose");
	LongDesc.Insert("FieldNameSeries", "TS.Series");
	
	Return LongDesc;
	
EndFunction

Function ThisIsDeliveryOrderToOurWarehouse(ReferenceOrder) Export
	If TypeOf(ReferenceOrder) = Type("DocumentRef.PurchaseOrder")
		Or TypeOf(ReferenceOrder) = Type("DocumentRef.VendorInvoice")
		Or TypeOf(ReferenceOrder) = Type("DocumentRef.GoodsReceiptForStorage")
		Or ReferenceOrder = "Document.GoodsReceiptForStorage"
		Or TypeOf(ReferenceOrder) = Type("CatalogRef.TermsOfPurchaseFromVendors")
		Or TypeOf(ReferenceOrder) = Type("CatalogRef.CounterpartyContracts")
		Or ReferenceOrder = "Document.PurchaseOrder"
		Or ReferenceOrder = "Document.VendorInvoice"
		Or ReferenceOrder = "Catalog.TermsOfPurchaseFromVendors"
		Or ReferenceOrder = "Catalog.CounterpartyContracts"
		Or (TypeOf(ReferenceOrder) = Type("FormDataStructure")
			Or TypeOf(ReferenceOrder) = Type("Structure"))
			And (TypeOf(ReferenceOrder.Ref) = Type("DocumentRef.PurchaseOrder")
				Or TypeOf(ReferenceOrder.Ref) = Type("DocumentRef.GoodsReceiptForStorage")
				Or TypeOf(ReferenceOrder.Ref) = Type("DocumentRef.VendorInvoice")
				Or TypeOf(ReferenceOrder.Ref) = Type("CatalogRef.TermsOfPurchaseFromVendors")
				Or TypeOf(ReferenceOrder.Ref) = Type("CatalogRef.CounterpartyContracts")) Then
		Return True;
	Else
		Return False;
	EndIf;
EndFunction

Function ThisIsInstructionForShippingAgent(ReferenceOrder) Export
	
	If TypeOf(ReferenceOrder) = Type("DocumentRef.InstructionForShippingAgent")
		Or ReferenceOrder = "Document.InstructionForShippingAgent"
		Or (TypeOf(ReferenceOrder) = Type("FormDataStructure")
				Or TypeOf(ReferenceOrder) = Type("Structure"))
			And (TypeOf(ReferenceOrder.Ref) = Type("DocumentRef.InstructionForShippingAgent")) Then
		Return True;
	Else
		Return False;
	EndIf;
EndFunction

Function AdditionalInfoIsInItemSelectionList(Item, AddlInfo)
	
	Return GoodsDeliveryClientServer.FindInListOfStructures(Item.ChoiceList,
			"AdditionalDeliveryInformation",AddlInfo) <> Undefined;
	
EndFunction

#EndRegion

#EndRegion