#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If GetFunctionalOption("ComplexAutomation") Then
		Items.GroupForDistributionByStage.Title = NStr("vi = 'Dạng chi phí theo xuất xưởng sản phẩm';
														|ru = 'Статей расходов по выпускам продукции';
														|en = 'Product release expense items'; fa = 'Product release expense items';
														|it = 'Voci di costo per l''output';
														|pl = 'Pozycji rozchodów wg wypuszczanej produkcji';
														|tr = 'İmal edilen ürün çıkışına ilişkin gider kalemleri'");
	EndIf;

	Items.GroupForDistributionByStage.Visible = False;
	Items.GroupForDistributionOfMaterialsAndWorks.Visible = False;
	Items.MetricsPage.Visible = False;	
	Items.ObsoleteRules.Visible = False;	
	Items.GroupForDistributionByStage.Visible = True;
	Items.GroupForDistributionOfMaterialsAndWorks.Visible = True;
	Items.MetricsPage.Visible = True;	
	Items.HIAIndicatorsPage.Visible = GetFunctionalOption("UseAccountingByExpenseObjects");	
	Items.ObsoleteRules.Visible = True;	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

#EndRegion
#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

