#Region Variables

&AtClient
Var IdleHandlerParameters;

&AtClient
Var TimeConsumingOperationForm;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	SetSceneryTitles();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure EnableEdit(Command)

	Close(True);

EndProcedure

&AtClient
Procedure CheckObjectUsage(Command)
	
	ChangeLockOfTMObjectAttributesClient.CheckObjectUsage(
		ThisForm,
		IdleHandlerParameters,
		True);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

#Region Other

&AtServer
Procedure SetSceneryTitles()
	
	ProductionIsUsed21 = ProductionServer.ProductionIsUsed21();
	ProductionIsUsed22 = ProductionServer.ProductionIsUsed22();
	
	// ExplanationOfTheProductMaterialsLaborCosts
	If ProductionIsUsed22 And ProductionIsUsed21 Then
		TitleText = NStr("vi = 'Danh sách bảng kê chi tiết các nguồn lực sản xuất, quy trình và các công đoạn sản xuất sẽ trở nên không chính xác.';
						|ru = 'Ресурсные спецификации, маршрутные листы и этапы производства станут некорректными.';
						|en = 'Bills of materials, operation sheets, and production stages will become invalid.'; fa = 'Bills of materials, operation sheets, and production stages will become invalid.';
						|it = 'Le specifiche delle risorse, dei fogli di lavorazione e i passaggi di produzione diventeranno errati.';
						|pl = 'Specyfikacje zasobów, listy przewozowe i etapy produkcji będą niepoprawne.';
						|tr = 'Ürün reçeteleri, işlem listeleri ve üretim aşamaları yanlış olacaktır.'");
	ElsIf ProductionIsUsed22 Then
		TitleText = NStr("vi = 'Danh sách bảng kê chi tiết các nguồn lực sản xuất và các công đoạn sản xuất sẽ trở nên không chính xác.';
						|ru = 'Ресурсные спецификации и этапы производства станут некорректными.';
						|en = 'Bills of materials and production stages will be incorrect.'; fa = 'Bills of materials and production stages will be incorrect.';
						|it = 'Le specifiche delle risorse e i passaggi di produzione diventeranno errati.';
						|pl = 'Specyfikacje zasobów i etapy produkcji będą niepoprawne.';
						|tr = 'Ürün reçeteleri ve üretim aşamaları yanlış olacaktır.'");
	Else
		TitleText = NStr("vi = 'Danh sách bảng kê chi tiết các nguồn lực sản xuất và danh sách quy trình sẽ trở nên không chính xác.';
						|ru = 'Ресурсные спецификации и маршрутные листы станут некорректными.';
						|en = 'Bills of materials and operation sheets will become invalid.'; fa = 'Bills of materials and operation sheets will become invalid.';
						|it = 'Le specifiche delle risorse e i fogli di lavorazione diventeranno errati.';
						|pl = 'Specyfikacje zasobów i listy przewozowe będą niepoprawne.';
						|tr = 'Ürün reçeteleri ve işlem listeleri yanlış olacaktır.'");
	EndIf;
	Items.ExplanationOfTheProductMaterialsLaborCosts.Title = TitleText;
	
	// OperationExplanation
	If ProductionIsUsed22 And ProductionIsUsed21 Then
		TitleText = NStr("vi = 'Sơ đồ quy trình và các công đoạn sản xuất sẽ  không chính xác.';
						|ru = 'Маршрутные листы и этапы производства станут некорректными.';
						|en = 'Operation sheets and production stages will become invalid.'; fa = 'Operation sheets and production stages will become invalid.';
						|it = 'Gli elenchi di rotte e i passaggi di produzione diventeranno errati.';
						|pl = 'Listy przewozowe i etapy produkcji będą niepoprawne.';
						|tr = 'İşlem listeleri ve üretim aşamaları yanlış olacaktır.'");
	ElsIf ProductionIsUsed22 Then
		TitleText = NStr("vi = 'Các công đoạn sản xuất sẽ trở nên không chính xác.';
						|ru = 'Этапы производства станут некорректными.';
						|en = 'Production stages will be incorrect.'; fa = 'Production stages will be incorrect.';
						|it = 'I passaggi di produzione diventeranno errati.';
						|pl = 'Etapy produkcji będą niepoprawne.';
						|tr = 'Üretim aşamaları yanlış olacaktır.'");
	Else
		TitleText = NStr("vi = 'Sơ đồ quy trình sẽ không chính xác.';
						|ru = 'Маршрутные листы станут некорректными.';
						|en = 'Operation sheets will become invalid.'; fa = 'Operation sheets will become invalid.';
						|it = 'I fogli di lavorazione diventeranno errati.';
						|pl = 'Listy przewozowe będą niepoprawne.';
						|tr = 'İşlem listeleri yanlış olacaktır.'");
	EndIf;
	Items.OperationExplanation.Title = TitleText;

EndProcedure

#EndRegion

#EndRegion
