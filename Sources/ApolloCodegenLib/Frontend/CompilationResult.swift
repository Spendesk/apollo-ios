import JavaScriptCore

/// The output of the frontend compiler.
public class CompilationResult: JavaScriptObject {
  lazy var operations: [OperationDefinition] = self["operations"]
  
  lazy var fragments: [FragmentDefinition] = self["fragments"]

  lazy var referencedTypes: [GraphQLNamedType] = self["referencedTypes"]
  
  public class OperationDefinition: JavaScriptObject {
    lazy var name: String = self["name"]
    
    lazy var operationType: OperationType = self["operationType"]
    
    lazy var variables: [VariableDefinition] = self["variables"]
    
    lazy var rootType: GraphQLCompositeType = self["rootType"]
    
    lazy var selectionSet: SelectionSet = self["selectionSet"]
    
    lazy var source: String = self["source"]
    
    lazy var filePath: String = self["filePath"]
    
    lazy var operationIdentifier: String = {
      // TODO: Compute this from source + referenced fragments
      fatalError()
    }()
  }
  
  public enum OperationType: String, Equatable, JavaScriptValueDecodable {
    case query
    case mutation
    case subscription
    
    init(_ jsValue: JSValue, bridge: JavaScriptBridge) {
      // No way to use guard when delegating to a failable initializer directly, but since this is a value type
      // we can initialize a local variable instead and assign it to `self` on success.
      // See https://forums.swift.org/t/theres-no-way-to-channel-a-fail-able-initializer-to-a-throwing-one-is-there/19322
      let rawValue: String = .fromJSValue(jsValue, bridge: bridge)
      guard let operationType = Self(rawValue: rawValue) else {
        preconditionFailure("Unknown GraphQL operation type: \(rawValue)")
      }
      
      self = operationType
    }
  }
  
  public class VariableDefinition: JavaScriptObject {
    lazy var name: String = self["name"]
    
    lazy var type: GraphQLType = self["type"]
    
    lazy var defaultValue: GraphQLValue? = self["defaultValue"]
  }
  
  public class FragmentDefinition: JavaScriptObject {
    lazy var name: String = self["name"]
    
    lazy var type: GraphQLCompositeType = self["type"]
    
    lazy var selectionSet: SelectionSet = self["selectionSet"]
    
    lazy var source: String = self["source"]
    
    lazy var filePath: String = self["filePath"]
  }
  
  public class SelectionSet: JavaScriptObject {
    lazy var parentType: GraphQLCompositeType = self["parentType"]
    
    lazy var selections: [Selection] = self["selections"]
  }
  
  public enum Selection: JavaScriptValueDecodable {
    case field(Field)
    case inlineFragment(InlineFragment)
    case fragmentSpread(FragmentSpread)
    
    init(_ jsValue: JSValue, bridge: JavaScriptBridge) {
      precondition(jsValue.isObject, "Expected JavaScript object but found: \(jsValue)")

      let kind: String = jsValue["kind"].toString()

      switch kind {
      case "Field":
        self = .field(Field(jsValue, bridge: bridge))
      case "InlineFragment":
        self = .inlineFragment(InlineFragment(jsValue, bridge: bridge))
      case "FragmentSpread":
        self = .fragmentSpread(FragmentSpread(jsValue, bridge: bridge))
      default:
        preconditionFailure("""
          Unknown GraphQL selection of kind "\(kind)"
          """)
      }
    }
  }
  
  public class Field: JavaScriptObject {
    lazy var name: String = self["name"]
    
    lazy var alias: String? = self["alias"]
    
    var responseKey: String {
      alias ?? name
    }
    
    lazy var arguments: [Argument]? = self["arguments"]
    
    lazy var type: GraphQLType = self["type"]
    
    lazy var selectionSet: SelectionSet? = self["selectionSet"]
    
    lazy var deprecationReason: String? = self["deprecationReason"]
    
    var isDeprecated: Bool {
      return deprecationReason != nil
    }
    
    lazy var description: String? = self["description"]
  }
  
  public class Argument: JavaScriptObject {
    lazy var name: String = self["name"]
    
    lazy var value: GraphQLValue = self["value"]
  }
  
  public class InlineFragment: JavaScriptObject {
    lazy var typeCondition: GraphQLCompositeType? = self["typeCondition"]
    
    lazy var selectionSet: SelectionSet = self["selectionSet"]
  }
  
  public class FragmentSpread: JavaScriptObject {
    lazy var fragment: FragmentDefinition = self["fragment"]
  }
}
