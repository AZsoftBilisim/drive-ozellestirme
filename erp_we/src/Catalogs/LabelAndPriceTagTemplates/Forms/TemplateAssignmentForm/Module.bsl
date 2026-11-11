
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	Template = Parameters.Template;
	Purpose = Parameters.Purpose;
	
	If Parameters.Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.GoodsPriceTag Then
		Items.AssignTo.ChoiceList.Add("Products", NStr("vi = 'Mặt hàng';
														|ru = 'Номенклатуры';
														|en = 'Items'; fa = 'اقلام';
														|it = 'Delgli articoli';
														|pl = 'Items';
														|tr = 'Öğeler'"));
		Items.AssignTo.ChoiceList.Add("ProductKind", NStr("vi = 'Dạng mặt hàng';
															|ru = 'Вида номенклатуры';
															|en = 'Of item kind'; fa = 'Of item kind';
															|it = 'Del tipo di articolo';
															|pl = 'Rodzaje towarów';
															|tr = 'Öğe türü'"));
		
		Products = Parameters.ForWhat;
		ProductKind = Common.ObjectAttributeValue(Parameters.ForWhat, "ProductKind");
		
	ElsIf Parameters.Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.GoodsLabel Then
		Items.AssignTo.ChoiceList.Add("Products", NStr("vi = 'Mặt hàng';
														|ru = 'Номенклатуры';
														|en = 'Items'; fa = 'اقلام';
														|it = 'Delgli articoli';
														|pl = 'Items';
														|tr = 'Öğeler'"));
		Items.AssignTo.ChoiceList.Add("ProductKind", NStr("vi = 'Dạng mặt hàng';
															|ru = 'Вида номенклатуры';
															|en = 'Of item kind'; fa = 'Of item kind';
															|it = 'Del tipo di articolo';
															|pl = 'Rodzaje towarów';
															|tr = 'Öğe türü'"));
		
		Products = Parameters.ForWhat;
		ProductKind = Common.ObjectAttributeValue(Parameters.ForWhat, "ProductKind");
		
	ElsIf Parameters.Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.LabelForStorageBins
		Or Parameters.Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.ExciseStampLabel
		Or Parameters.Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.LabelForBarcodesPackages
		Or Parameters.Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.AssetLabelTape 
		Or Parameters.Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.AssetLabelPaper 
		Or Parameters.Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.SubAssetLabelTape 
		Or Parameters.Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.SubAssetLabelPaper 
		Or Parameters.Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.LabelInventoryInOperationTape 
		Or Parameters.Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.LabelInventoryInOperationPaper 
		Or Parameters.Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.LabelShoesClothesTobacco Then
		Items.AssignTo.ChoiceList.Add("Prohibited", NStr("vi = 'Chưa ấn định';
														|ru = 'Не назначается';
														|en = 'Not assigned'; fa = 'تخصیص نیافته';
														|it = 'Non si assegna';
														|pl = 'Nie przydziela się';
														|tr = 'Atanmıyor'"));
	ElsIf Parameters.Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.ItemsBatchLabel Then
		Items.AssignTo.ChoiceList.Add("ProductKind", NStr("vi = 'Dạng mặt hàng';
															|ru = 'Вида номенклатуры';
															|en = 'Of item kind'; fa = 'Of item kind';
															|it = 'Del tipo di articolo';
															|pl = 'Rodzaje towarów';
															|tr = 'Öğe türü'"));
	ElsIf Parameters.Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.LabelForDelivery Then
		Items.AssignTo.ChoiceList.Add("Partner", NStr("vi = 'Khách hàng\Người vận chuyển';
														|ru = 'Клиента\Перевозчика';
														|en = 'Customer\Shipper'; fa = 'Customer\Shipper';
														|it = 'Del cliente   del fornitore';
														|pl = 'Customer\Shipper';
														|tr = 'İstemcinin\Taşıyıcının'"));
	EndIf;
	
	AssignTo = Items.AssignTo.ChoiceList.Get(0).Value;
	
	If Items.AssignTo.ChoiceList.Count() < 2 Then
		Items.AssignTo.Visible = False;
	EndIf;
	
	WhenChangingDestination(ThisObject);

	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure AssignToOnChange(Item)
	
	WhenChangingDestination(ThisForm);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Assign(Command)
	AssignOnServer();
	Close();
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

#Region Other

&AtServer
Procedure AssignOnServer()
	
	SetPrivilegedMode(True);
	
	If Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.GoodsPriceTag Then
		
		If AssignTo = "Products" Then
			Object = Products.GetObject();
			Object.PriceTagTemplate = Template;
			Object.UseCustomPriceTagTemplate = True;
			Object.Write();
		ElsIf AssignTo = "ProductKind" Then
			Object = ProductKind.GetObject();
			Object.PriceTagTemplate = Template;
			Object.Write();
		EndIf;
		
	ElsIf Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.GoodsLabel Then
		
		If AssignTo = "Products" Then
			Object = Products.GetObject();
			Object.LabelsTemplate = Template;
			Object.UseCustomTemplateLabels = True;
			Object.Write();
		ElsIf AssignTo = "ProductKind" Then
			Object = ProductKind.GetObject();
			Object.LabelsTemplate = Template;
			Object.Write();
		EndIf;
		
	ElsIf Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.LabelForStorageBins Then
		
	ElsIf Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.ItemsBatchLabel Then
		
		Object = ProductKind.GetObject();
		Object.LabelTemplateBatches = Template;
		Object.Write();
		
	ElsIf Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.LabelForDelivery Then
		
		Object = Partner.GetObject();
		Object.LabelsTemplate = Template;
		Object.Write();
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure WhenChangingDestination(Form)

	If Form.AssignTo = "Products" Then
		Form.Items.GroupPages.CurrentPage = Form.Items.NomenclatureGroup;
	ElsIf Form.AssignTo = "ProductKind" Then
		Form.Items.GroupPages.CurrentPage = Form.Items.GroupProductKind;
	ElsIf Form.AssignTo = "Prohibited" Then
		Form.Items.GroupPages.CurrentPage = Form.Items.GroupForbidden;
	ElsIf Form.AssignTo = "Partner" Then
		Form.Items.GroupPages.CurrentPage = Form.Items.GroupPartner;
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion
