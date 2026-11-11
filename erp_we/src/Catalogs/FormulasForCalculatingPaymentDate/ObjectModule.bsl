#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text = "
	|SELECT TOP 1 
	|	Catalog.Ref
	|FROM
	|	Catalog.FormulasForCalculatingPaymentDate AS Catalog
	|WHERE
	|	Catalog.Description = &Description
	|	AND Catalog.Ref <> &Ref";
	Query.SetParameter("Description", Description);
	Query.SetParameter("Ref", Ref);
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Common.MessageToUser(StrTemplate(NStr("ru = 'Уже существует формула с наименованием %1.';
												|vi = 'A formula with the %1 description already exists.';
												|en = 'A formula with the %1 description already exists.'; fa = 'A formula with the %1 description already exists.';
												|it = 'A formula with the %1 description already exists.';
												|pl = 'A formula with the %1 description already exists.';
												|tr = '%1 adıyla bir formül zaten mevcut.'"),Description),,,,Cancel);
	EndIf;
	
	If StrFind(Formula, "DateOfShipment") > 0
		Or StrFind(Formula, "DateOfReceipt") > 0
		Or StrFind(Formula, "DateOfTransferOfTitleToGoods") > 0 Then
		DependsOnShipmentDate = True;
	Else
		DependsOnShipmentDate = False;
	EndIf;
	
EndProcedure

#EndRegion

#EndIf