#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If Parameters.InteractionBasis.IsEmpty() Then
		
		Cancel = True;
		Return;
		
	EndIf;
	
	// If there is no access right to the "Interaction" subsystem, then there is nothing to show.
	If Not AccessRight("View", Metadata.DocumentJournals.Interactions) Then
		CommonClientServer.MessageToUser(NStr("vi = 'Bạn không có quyền xem báo cáo về các chứng từ đã tạo để gửi hàng loạt.';
												|ru = 'У вас нет прав на просмотр отчета по созданным документам рассылки.';
												|en = 'You are not authorized to view the report on the created mailout documents.'; fa = 'You are not authorized to view the report on the created mailout documents.';
												|it = 'Non avete il diritto di consultare il report sui documenti di mailing creati.';
												|pl = 'Nie masz uprawnień do wyświetlania raportu na temat utworzonych dokumentów newslettera.';
												|tr = 'Oluşturulan dağıtım belgeleriyle ilgili raporu görüntüleme yetkiniz bulunmamaktadır.'"));
		Cancel = True;
		Return;
	EndIf;
	
	InteractionBasis = Parameters.InteractionBasis;

	CommonClientServer.SetDynamicListParameter(
	          List,
	          "InteractionBasis",
	          InteractionBasis);
	
	VisibilityManagement();
	
EndProcedure

#EndRegion

#Region FormHeaderEventHandlers

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	Cancel = True;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure VisibilityManagement()

	DesignedForEmails      = Common.ObjectAttributeValue(InteractionBasis, "DesignedForEmails");
	Items.SentReceived.Visible = DesignedForEmails;
	Items.HasAttachments.Visible       = DesignedForEmails;

EndProcedure 


#EndRegion
