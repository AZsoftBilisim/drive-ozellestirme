// @strict-types

#Region Public

// Returns the versions of the message interface supported by the information Security correspondent.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//  MessageInterface - String - Name of the message programming interface.
//  ConnectionParameters - Structure - Parameters for connecting to an IB correspondent.
//  RecipientPresentation1 - String - Representation of the IB correspondent.
//  CurIBInterface - String - Name of the software interface of the current is (used
//    for backward compatibility with previous versions of the BSP).
//
// Returns:
//  String - the maximum version of the interface supported by both the correspondent IB and the current IB.
//
Function CorrespondentInterfaceVersion(Val MessageInterface, Val ConnectionParameters, 
	Val RecipientPresentation1, Val CurIBInterface = "") Export	
EndFunction

#EndRegion

#Region Internal

// See CommonOverridable.OnDefineSupportedInterfaceVersions
// @skip-warning EmptyMethod - a feature of the implementation.
// 
// Parameters:
//	SupportedVersionsStructure 
//	 - See CommonOverridable.OnDefineSupportedInterfaceVersions.SupportedVersions
//
Procedure OnDefineSupportedInterfaceVersions(Val SupportedVersionsStructure) Export
EndProcedure

// See MessagesExchangeOverridable.GetMessagesChannelsHandlers
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//	Handlers - See MessagesExchangeOverridable.GetMessagesChannelsHandlers.Handlers
//
Procedure OnDefineMessagesChannelsHandlers(Handlers) Export
EndProcedure

// Returns a fixed array filled with common modules 
// that are handlers of received message interfaces.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Returns:
//  FixedArray of CommonModule
//
Function GetHandlersForReceivedMessageInterfaces() Export
EndFunction

// Returns the names of the message channels from the specified package.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//  PackageURI - String - URI of the XDTO package, message types to get from.
//  BaseType - XDTODataObject - base type.
//
// Returns:
//  FixedArray of String - channel names found in the package.
//
Function GetPackageChannels(Val PackageURI, Val BaseType) Export	
EndFunction

#EndRegion

