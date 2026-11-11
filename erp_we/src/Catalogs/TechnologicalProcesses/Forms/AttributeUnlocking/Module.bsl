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
	
	// Explanation of Material Labor costs
	TitleText = NStr("vi = 'Danh sách bảng kê chi tiết các nguồn lực sản xuất và các công đoạn sản xuất sẽ trở nên không chính xác.';
					|ru = 'Ресурсные спецификации и этапы производства станут некорректными.';
					|en = 'Bills of materials and production stages will be incorrect.'; fa = 'Bills of materials and production stages will be incorrect.';
					|it = 'Le specifiche delle risorse e i passaggi di produzione diventeranno errati.';
					|pl = 'Specyfikacje zasobów i etapy produkcji będą niepoprawne.';
					|tr = 'Ürün reçeteleri ve üretim aşamaları yanlış olacaktır.'");
	Items.ExplanationOfTheProductMaterialsLaborCosts.Title = TitleText;
	
	// OperationExplanation
	TitleText = NStr("vi = 'Các công đoạn sản xuất sẽ trở nên không chính xác.';
					|ru = 'Этапы производства станут некорректными.';
					|en = 'Production stages will be incorrect.'; fa = 'Production stages will be incorrect.';
					|it = 'I passaggi di produzione diventeranno errati.';
					|pl = 'Etapy produkcji będą niepoprawne.';
					|tr = 'Üretim aşamaları yanlış olacaktır.'");
	Items.OperationExplanation.Title = TitleText;

EndProcedure

#EndRegion

#EndRegion
