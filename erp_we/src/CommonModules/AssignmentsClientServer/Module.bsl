////////////////////////////////////////////////////////////////
// The Clientserver Assignments module contains procedures and functions for 
// working with assignments on the client and on the server.
//
////////////////////////////////////////////////////////////////

#Region Public

#Region FillType

// Returns filling parameters by destination type
// 
// Returns:
//  Structure - with keys:
// * NameOfFieldToFillIn - String                            - Name Of The Field To Fill In
// * TSFieldName           - String, Undefined              - Source fill-in value, higher priority than field value
// * Simple        - Arbitrary                      - fill-in value
// * AssignmentType       - EnumRef.AssignmentTypes - the type of destination for which the specified field is filled with the specified value
//
Function FillParameters() Export
	
	Parameters = New Structure;
	Parameters.Insert("NameOfFieldToFillIn");
	Parameters.Insert("TSFieldName");
	Parameters.Insert("Simple");
	Parameters.Insert("AssignmentType");
	
	Return Parameters;
	
EndFunction

// It is intended for use in Forms of documents in event handlers that lead to a change in the assignment in
// the row of the table part of the document. Adds an action to the structure of actions, which is worked out by the mechanisms
// for processing table parts, See BatchProcessingOfTablePartClient.ProcessTSString
// Performing such
// an action updates the assignment in the row of the tabular part of the document, in accordance with the changed direction of activity.
//
// Parameters:
//  Form - ClientApplicationForm - A form in which you need to perform an action to process a row in the table part.
//  StructureOfActions - Structure - The structure of actions used by the mechanisms for processing tabular parts (see
//                                  the batch processing procedure for a tabular partclient.Process a line by line).
//  IsOutdated - Boolean - For compatibility with the activity directionclientserver.The structure of the action to add addendesreferences
Procedure StructureOfInsertActionsWhenAddingRow(Form, StructureOfActions, IsOutdated = False) Export
	
	If IsOutdated Then
		DocumentProcessingProcedure = Form.FormMetadata;
		Cache = Form.LineOfBusinessCachedValues;
	Else
		DocumentProcessingProcedure = Form.AssignmentsCachedValues.DocumentProcessingProcedure;
		Cache = Form.AssignmentsCachedValues;
	EndIf;
	
	OrderDetailsName = DocumentProcessingProcedure.OrderDetailsName;
	PropsNameIsSeparate = DocumentProcessingProcedure.Utilities.PropsNameIsSeparate;

	DefaultAssignment = Undefined;
	If OrderDetailsName = Undefined
		Or Not ValueIsFilled(Form.Object[OrderDetailsName])
		Or Not Form.Object[OrderDetailsName] Then
			DefaultAssignment = Cache.DefaultAssignment;
	EndIf;
		
	StructureOfActions.Insert("CheckFillAssignment", DefaultAssignment);
	
	If PropsNameIsSeparate <> Undefined And ValueIsFilled(DefaultAssignment) Then
		StructureOfActions.Insert("FillFlagSeparatelyAsIntended", PropsNameIsSeparate);
	EndIf;
	
EndProcedure

// Fills in the invisible Destination field in documents based on the filled-in field Separately.
// 
// Parameters:
//  Form - ClientApplicationForm - A form in which you need to perform an action to process a row in the table part.
//  CurrentRow - FormDataCollectionItem - the line where you need to fill in the assignment based on the separate flag.
//  IsOutdated - Boolean - For compatibility with the activity directionclientserver.Fill in the assignment of the form separately
Procedure FillAssignmentByFlagSeparately(Form, CurrentRow, IsOutdated = False) Export
	
	If IsOutdated Then
		DefaultAssignment = Form.LineOfBusinessCachedValues.DefaultAssignment;
	Else
		DefaultAssignment = Form.AssignmentsCachedValues.DefaultAssignment;
	EndIf;
	If CurrentRow.WithAssignment Then
		
		CurrentRow.Purpose = DefaultAssignment;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormationOfPresentation

// Defines the Presentation of the destination type by the destination Attributes.
// Parameters:
//  DetailsOfAppointment - Structure - structure with fields:
//   * OrderDocument - See Catalog.Assignments.OrderDocument
//   * Contract - See Catalog.Assignments.Contract
//   * Partner - See Catalog.Assignments.Partner
//   * AssignmentType - See Catalog.Assignments.AssignmentType
//  LanguageCode - String - the language code.
// Returns:
//  String - Presentation
Function DestinationTypePresentation(DetailsOfAppointment, LanguageCode) Export
	
	Result = Undefined;
	If ValueIsFilled(DetailsOfAppointment.OrderDocument) Then
		
		DocumentType = TypeOf(DetailsOfAppointment.OrderDocument);
		
		If DocumentType = Type("DocumentRef.ByAssemblyDisassemblyOrder") Then
			Result = NStr("vi = 'Đơn hàng đóng bộ (tách bộ)';
							|ru = 'Заказ на сборку (разборку)';
							|en = 'Kitting order'; fa = 'سفارش کیت‌سازی';
							|it = 'Ordine di assemblaggio/disassemblaggio';
							|pl = 'Zamówienie na montaż';
							|tr = 'Montaj emri (demontaj)'", LanguageCode);
		ElsIf DocumentType = Type("DocumentRef.TransferOrder") Then
			Result = NStr("vi = 'Đơn hàng điều chuyển nội bộ';
							|ru = 'Заказ на перемещение';
							|en = 'Transfer order'; fa = 'سفارش انتقال';
							|it = 'Ordine di trasferimento';
							|pl = 'Zamówienie na przesunięcie';
							|tr = 'Transfer emri'", LanguageCode);
		ElsIf DocumentType = Type("DocumentRef.InventoryConsumptionOrder") Then
			Result = NStr("vi = 'Đơn hàng tiêu dùng nội bộ';
							|ru = 'Заказ на внутреннее потребление';
							|en = 'Inventory consumption order'; fa = 'سفارش مصرف موجودی';
							|it = 'Ordine per il consumo interno';
							|pl = 'Zamówienie na konsumpcję wewnętrzną';
							|tr = 'İç tüketim siparişi'", LanguageCode);
		ElsIf DocumentType = Type("DocumentRef.SalesOrder") Then
			Result = NStr("vi = 'Đơn hàng của khách';
							|ru = 'Заказ клиента';
							|en = 'Sales order'; fa = 'سفارش فروش';
							|it = 'Ordine del cliente';
							|pl = 'Zamówienie klienta';
							|tr = 'Satış siparişi'", LanguageCode);
		ElsIf DocumentType = Type("DocumentRef.RequestForReturnOfGoodsFromCustomer") Then
			Result = NStr("vi = 'Giấy đề nghị trả hàng từ người mua';
							|ru = 'Заявка на возврат товаров от клиента';
							|en = 'Sales return request'; fa = 'درخواست برگشت از فروش';
							|it = 'Richiesta di reso della merce dal cliente';
							|pl = 'Wniosek o zwrot towarów od klienta';
							|tr = 'Müşterinin ürün iadesi talebi'", LanguageCode);
		ElsIf DocumentType = Type("DocumentRef.OrderOfMaterialsForProduction") Then
			Result = NStr("ru = 'Заказ материалов в производство';
							|vi = 'Material order for shop floor stockroom';
							|en = 'Material order for shop floor stockroom'; fa = 'سفارش مواد برای انبار کارگاه';
							|it = 'Ordine dei materiali nella produzione';
							|pl = 'Zamówienie materiałów do produkcji';
							|tr = 'Üretim için malzeme siparişi'", LanguageCode);
		ElsIf DocumentType = Type("DocumentRef.SubcontractOrder2_5") Then
			Result = NStr("ru = 'Заказ переработчику';
							|vi = 'Subcontracting purchase order';
							|en = 'Subcontracting purchase order'; fa = 'سفارش خرید پیمانکاری فرعی';
							|it = 'Ordine al subfornitore';
							|pl = 'Zamówienie do przetwórcy';
							|tr = 'Fason satın alma siparişi'", LanguageCode);
		ElsIf DocumentType = Type("DocumentRef.MaterialProviderOrder2_5") Then
			Result = NStr("ru = 'Заказ давальца';
							|vi = 'Subcontracting sales order';
							|en = 'Subcontracting sales order'; fa = 'سفارش فروش پیمانکاری فرعی';
							|it = 'Ordine del committente';
							|pl = 'Zamówienie dostawcy';
							|tr = 'Tedarikçi siparişi'", LanguageCode);
		ElsIf DocumentType = Type("DocumentRef.RMOrder") Then
			Result = NStr("ru = 'Заказ на ремонт';
							|vi = 'R&M order';
							|en = 'R&M order'; fa = 'سفارش تعمیر و نگهداری';
							|it = 'Ordine di manutenzione';
							|pl = 'Zamówienie naprawy';
							|tr = 'Onarım siparişi'", LanguageCode);
		ElsIf DocumentType = Type("DocumentRef.ProductionStage2_2") Then
			Result = NStr("ru = 'Этап производства';
							|vi = 'Production stage';
							|en = 'Production stage'; fa = 'مرحله تولید';
							|it = 'Fase di produzione';
							|pl = 'Etap produkcji';
							|tr = 'Üretim aşaması'", LanguageCode);
		ElsIf DocumentType = Type("DocumentRef.ProductionOrder2_2") Then
			Result = NStr("ru = 'Заказ на производство';
							|vi = 'Production order';
							|en = 'Production order'; fa = 'سفارش تولید';
							|it = 'Ordine di produzione';
							|pl = 'Zlecenie produkcyjne';
							|tr = 'Üretim emri'", LanguageCode);
		EndIf;
		
	ElsIf ValueIsFilled(DetailsOfAppointment.Contract) Then
		
		If DetailsOfAppointment.AssignmentType = PredefinedValue("Enum.AssignmentTypes.DeliveryForPrincipal") Then
			Result = NStr("ru = 'Закупка под принципала';
							|vi = 'Purchase for principal';
							|en = 'Purchase for principal'; fa = 'Purchase for principal';
							|it = 'Acquisto conto mandante';
							|pl = 'Zakup według zleceniodawcy';
							|tr = 'Müvekkil adına satın alma'", LanguageCode);
		ElsIf DetailsOfAppointment.AssignmentType = PredefinedValue("Enum.AssignmentTypes.Giveaway2_5")
				Or False Then
				Result = NStr("vi = 'Hợp đồng với bên đặt gia công';
								|ru = 'Договор с давальцем';
								|en = 'Subcontracting agreement'; fa = 'قرارداد پیمانکاری فرعی';
								|it = 'Accordo con il committente';
								|pl = 'Umowa z właścicielem surowca';
								|tr = 'Tedarikçi sözleşmesi'", LanguageCode);
		Else
			Result = NStr("vi = 'Hợp đồng với bên nhận gia công';
							|ru = 'Договор с переработчиком';
							|en = 'Contract with subcontractor'; fa = 'Contract with subcontractor';
							|it = 'Accordo con il subfornitore';
							|pl = 'Umowa z przetwórcą';
							|tr = 'Fason üretici sözleşmesi'", LanguageCode);
		EndIf;
		
	ElsIf ValueIsFilled(DetailsOfAppointment.Partner) Then
		
		If DetailsOfAppointment.AssignmentType = PredefinedValue("Enum.AssignmentTypes.Giveaway2_5")
			Or False Then
			Result = NStr("vi = 'Bên đặt gia công';
							|ru = 'Давалец';
							|en = 'Material provider'; fa = 'تأمین‌کننده مواد';
							|it = 'Committente';
							|pl = 'Właściciel surowców';
							|tr = 'Malzeme tedarikçisi'", LanguageCode);
		Else
			Result = NStr("vi = 'Bên nhận gia công';
							|ru = 'Переработчик';
							|en = 'Subcontractor'; fa = 'پیمانکار فرعی';
							|it = 'Subfornitore';
							|pl = 'Przetwórca';
							|tr = 'Fason üretici'", LanguageCode);
		EndIf;
		
	Else
		
		Result = NStr("ru = 'Направление деятельности';
						|vi = 'Line of business';
						|en = 'Line of business'; fa = 'خط کسب‌وکار';
						|it = 'Settore di attività';
						|pl = 'Rodzaj działalności';
						|tr = 'İş kolu'", LanguageCode);
		
	EndIf;
	
	Return Result;

EndFunction

#EndRegion

#EndRegion