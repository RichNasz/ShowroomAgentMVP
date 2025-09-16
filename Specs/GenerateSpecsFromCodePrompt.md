# Generate Specifications from Code Prompt

## Purpose

This prompt is designed to generate three complementary specification documents from source code analysis:

1. **Functional Specification** (`[SystemName]Spec.md`) - Focuses on WHAT the code accomplishes
2. **Generic Code Generation Specification** (`CodeGenerationSpec.md`) - Focuses on HOW to implement the functionality (language-agnostic)
3. **Language-Specific Implementation Guide** (`[Language]CodeGeneration.md`) - Focuses on implementation details for specific programming languages

## Instructions for AI Systems

You are tasked with analyzing source code to create three distinct but complementary specification documents. Follow this structured approach to ensure comprehensive and accurate documentation.

---

## Phase 1: Source Code Analysis

### Step 1: Codebase Exploration
1. **Discover all source files** using file discovery tools
2. **Read all source code files** to understand complete functionality
3. **Examine configuration files, tests, and documentation** for additional context
4. **Identify key data structures, public APIs, and core capabilities**
5. **Note dependencies, platform requirements, and technical constraints**

### Step 2: Functional Analysis
Extract and categorize:
- **Core purpose and objectives** of the system
- **Input/output relationships** and data transformations
- **Supported formats, structures, and patterns**
- **Error handling and validation approaches**
- **Performance characteristics and scalability**
- **Integration patterns and extensibility points**

---

## Phase 2: Generate Functional Specification

Create `[SystemName]Spec.md` (i.e `MySystemNameSpec.md ) focusing on **WHAT** the code accomplishes.

### Required Structure:

#### 1. **Overview Section**
- **Core purpose** and value proposition
- **Target use cases** and scenarios
- **Key benefits** for users

#### 2. **Repository/System Structure Support**
- **Expected input formats** and organization patterns
- **Directory structures** and file conventions
- **Configuration system** overview

#### 3. **Functional Capabilities Summary**
Create a table with:
```markdown
| Capability | Description | Key Benefits |
|------------|-------------|--------------|
| **Feature Name** | What it does in 1-2 sentences | Why it matters to users |
```

Follow with **Core Value Propositions** highlighting main strengths.

#### 4. **Detailed Functional Capabilities**
Number each major capability (1, 2, 3, etc.) with:
- **Purpose**: What the capability accomplishes
- **Input/Output**: What goes in and what comes out
- **Process**: High-level steps (without implementation details)
- **Capabilities**: Specific features and support
- **Use Cases**: When and why to use this capability

#### 5. **Advanced Content Processing**
Document specialized processing features that go beyond basic functionality.

#### 6. **Data Models**
Describe key data structures and their purposes (without implementation details):
- **What each model represents**
- **Key relationships** between models
- **Purpose and usage** of each structure

#### 7. **Performance Characteristics**
- **Speed benchmarks** for different workloads
- **Memory usage** patterns
- **Scalability** characteristics
- **Performance factors** that affect speed

#### 8. **Use Cases**
Organize by category:
- **Primary use cases** with detailed scenarios
- **Integration patterns** for different environments
- **Real-world applications** and examples

#### 9. **Error Handling Philosophy**
- **Approach to failures** and edge cases
- **Resilience strategies** and graceful degradation
- **User experience** during error conditions

#### 10. **Development and Testing Capabilities**
- **Environment support** and compatibility
- **Testing approaches** and validation
- **Cross-platform behavior**

#### 11. **Integration Patterns**
- **How the system integrates** with other tools
- **Extension points** and customization
- **Workflow integration** patterns

#### 12. **Extensibility**
- **How the system can be enhanced**
- **Supported customizations**
- **Future enhancement** possibilities

### Content Guidelines for Functional Spec:
- **Focus on capabilities, not implementation**
- **Use benefit-oriented language** that explains value
- **Include concrete examples** of supported formats/patterns
- **Emphasize user outcomes** and achievements
- **Avoid technical implementation details**
- **Write for evaluation and decision-making**

### WHAT vs HOW Separation Rules:
**Include in Functional Spec (WHAT):**
- What the system can accomplish
- What formats/structures are supported
- What benefits users gain
- What use cases are enabled
- What error handling approach is used
- What performance characteristics exist

**Move to Code Generation Spec (HOW):**
- Stack-based algorithms or specific algorithms
- Pattern matching implementations
- Parsing combinators usage
- State management techniques
- Precedence rules for merging
- String normalization methods
- Multi-location file resolution strategies
- Type conversion implementations
- Error message format patterns

---

## Phase 3: Generate Generic Code Generation Specification

Create `CodeGenerationSpec.md` focusing on **HOW** to implement the functionality using language-agnostic algorithms and patterns.

### Required Structure:

#### 1. **Purpose and Scope**
- **Clear differentiation** from functional spec
- **Target audience**: AI code generation tools targeting any programming language
- **Scope**: Language-agnostic algorithms, data structures, and processing patterns
- **Related documents**: Links to functional spec and language-specific guides

#### 2. **Core Data Model Relationships**
- **Entity hierarchy** and relationships
- **Data flow patterns** between components
- **Essential data structures** with their purposes
- **Generic entity definitions** without language-specific syntax

#### 3. **Core Processing Algorithms**
- **Repository discovery and validation** algorithms
- **Configuration resolution** patterns
- **Navigation hierarchy processing** algorithms
- **Content parsing** strategies
- **Cross-reference analysis** methods
- **Format conversion** algorithms
- **All algorithms in pseudocode** format

#### 4. **Error Handling and Recovery Strategies**
- **Graceful degradation** patterns
- **File-level error recovery** approaches
- **Validation and error reporting** strategies
- **Partial success** handling methods
- **Error message formatting** standards

#### 5. **Performance Optimization Strategies**
- **Memory management** patterns
- **Processing optimization** techniques
- **Lazy evaluation** approaches
- **Efficient text processing** methods

#### 6. **Testing and Validation Patterns**
- **Systematic testing** approaches
- **Element classification** testing
- **Integration testing** patterns
- **Error scenario** validation methods

#### 7. **Implementation Checklist**
- **Core requirements** for functionality
- **Data model requirements** needed
- **Algorithm requirements** to implement
- **Testing requirements** for validation

### Content Guidelines for Generic Code Generation Spec:
- **Use pseudocode** for all algorithms and patterns
- **Focus on logic and flow** rather than syntax
- **Provide comprehensive algorithm descriptions** with step-by-step processes
- **Include data relationships** and entity interactions
- **Document error handling strategies** at the algorithmic level
- **Specify performance optimization** patterns that apply across languages

---

## Phase 4: Generate Language-Specific Implementation Guide

Create `[Language]CodeGeneration.md` (e.g., `SwiftCodeGeneration.md`) focusing on **HOW** to implement the generic algorithms using specific language features, libraries, and idioms.

### Required Structure:

#### 1. **Purpose and Scope**
- **Clear relationship** to generic specification
- **Target audience**: AI code generation tools and developers using specific language
- **Prerequisites**: Required language version, tools, and understanding
- **Related documents**: Links to functional and generic specs

#### 2. **Language Project Setup**
- **Package/build system** configuration
- **Dependency specifications** and library versions
- **Module organization** and file structure
- **Required imports** and namespace usage

#### 3. **Language-Specific Data Model Implementation**
- **Type system usage** (structs, classes, enums, interfaces)
- **Immutability patterns** and data model organization
- **Collection handling** and relationship management
- **Language-specific features** for data modeling

#### 4. **Language-Specific Algorithm Contracts**
- **Function signatures and behavioral requirements** for generic algorithms
- **Library integration patterns** (parsing, YAML, file system)
- **Language idioms** and best practices as contracts
- **Error handling patterns** and requirements specific to the language

#### 5. **Platform-Specific Features**
- **Environment detection** and conditional compilation
- **Platform APIs** and file system operations
- **IDE integration** and development tools
- **Cross-platform considerations**

#### 6. **Language-Specific Testing Contracts**
- **Testing framework** integration patterns and requirements
- **Language testing idioms** and contract specifications
- **Mock and test data** management approaches
- **Type-safe assertion** patterns and requirements

#### 7. **Performance Optimization Contracts for Language**
- **Language-specific optimization** requirements and patterns
- **Memory management** strategy contracts
- **Concurrency** and parallelism opportunity specifications
- **Profiling and debugging** approach requirements

#### 8. **Extension-Based Architecture Contracts**
- **Language extension patterns** and requirements for modularity
- **Domain-specific language features** as contracts
- **Code organization** strategy requirements
- **API design** principle specifications

#### 9. **Implementation Checklist for Language**
- **Language-specific requirements** and features
- **Library integration** tasks
- **Performance optimization** implementations
- **Testing infrastructure** setup

### Content Guidelines for Language-Specific Guide:
- **Provide function signatures and contracts** rather than complete implementations
- **Use language-specific syntax** for signatures and type definitions
- **Specify integration requirements** with language ecosystem tools and libraries
- **Define error handling patterns** and requirements using language conventions
- **Specify testing approach contracts** using language frameworks
- **Include platform-specific** requirements and optimization contracts

### Balance Implementation vs. Contracts:
**Provide Complete Implementations For:**
- **Project setup** and build system configuration
- **Library integration** examples and setup patterns
- **Platform-specific** conditional compilation examples
- **Testing framework** integration and setup

**Provide Contracts and Requirements For:**
- **Core algorithm** implementations (let AI optimize)
- **Data structure** implementations (specify requirements)
- **Business logic** functions (define contracts)
- **Performance optimizations** (specify patterns and requirements)

---

## Phase 5: Quality Assurance

### Cross-Reference Validation
1. **Ensure functional spec capabilities** have corresponding implementation guidance in both generic and language-specific specs
2. **Verify generic code generation spec covers** all functional requirements with language-agnostic algorithms
3. **Confirm language-specific guide** implements all generic algorithms with appropriate language features
4. **Check for consistency** between all three documents
5. **Validate examples** are accurate and complete across specifications
6. **Review WHAT vs HOW separation** - ensure no implementation details leaked into functional spec
7. **Verify generic algorithms** are truly language-agnostic in code generation spec
8. **Check that language-specific details** are only in language guide, not generic spec

### Completeness Check
- **All major functionality** documented in functional spec
- **All algorithms** covered in generic code generation spec
- **All language features** utilized in language-specific guide
- **All use cases** addressed in functional spec
- **All error scenarios** handled in all documents
- **All performance considerations** covered appropriately

### Accuracy Verification
- **Technical details** match actual implementation
- **Examples** are realistic and working
- **Performance claims** are substantiated
- **Dependencies** are correctly specified

---

## Output Format Requirements

### File Organization
```
Specs/
├── [SystemName]Spec.md           # Functional specification (WHAT)
├── CodeGenerationSpec.md         # Generic implementation specification (HOW - language-agnostic)
├── [Language]CodeGeneration.md   # Language-specific implementation guide (HOW - language-specific)
└── GenerateSpecsFromCodePrompt.md # This prompt file
```

### Document Structure
- **Use markdown formatting** for readability
- **Include clear section headers** with consistent numbering
- **Use tables** for systematic information
- **Apply bold text** for key concepts and emphasis
- **Create numbered lists** for sequential information
- **Use code blocks** for examples and patterns

### Cross-References
- **Link between documents** where appropriate
- **Reference related sections** within documents
- **Provide clear navigation** between functional and implementation details

---

## Success Criteria

The generated specifications should enable:

### For Functional Specification:
1. **Quick understanding** of system capabilities and value
2. **Informed evaluation** for adoption decisions
3. **Use case identification** and scenario planning
4. **Integration assessment** and workflow planning

### For Generic Code Generation Specification:
1. **Language-agnostic implementation** guidance for any programming language
2. **Complete algorithmic coverage** without missing functionality
3. **Universal error handling** patterns and approaches
4. **Consistent logical behavior** across different language implementations

### For Language-Specific Implementation Guide:
1. **Flexible AI code generation** with contracts that allow optimization
2. **Proper integration** with language ecosystem and tools
3. **Optimal performance** through AI-selected implementations within contract constraints
4. **Idiomatic code generation** following language conventions and best practices
5. **Creative freedom** for AI to generate optimal solutions within specified requirements

### For All Documents:
1. **Comprehensive coverage** of all significant functionality
2. **Clear separation** between WHAT, generic HOW, and language-specific HOW
3. **Mutual support** and complementary information across all three specs
4. **Professional quality** suitable for production use and multi-language implementations

---

## Usage Instructions

1. **Run this prompt** against any source codebase
2. **Follow the phases sequentially** for best results
3. **Generate all three specifications** for comprehensive coverage
4. **Customize section names** to match the specific domain and programming language
5. **Validate completeness** against the success criteria
6. **Update as needed** when source code evolves

This prompt ensures consistent, comprehensive, and accurate specification generation that serves human users, generic algorithm understanding, and language-specific AI code generation tools effectively.

---

## Critical Implementation Details That Must Be Separated

### Generic HOW Details That Belong in Generic Code Generation Spec:

**Algorithm Specifics (Pseudocode):**
- Stack-based processing approaches
- Multi-step resolution strategies  
- State transition logic and management
- Precedence rule implementations
- File system operation strategies

**Processing Strategies (Language-Agnostic):**
- Line-by-line processing techniques
- Memory optimization approaches
- Configuration merging logic
- Multi-location file resolution algorithms
- Cross-reference extraction methods
- Error recovery sequences and handling patterns

### Language-Specific HOW Details That Belong in Language Implementation Guide:

**Language-Specific Implementation:**
- Concrete syntax and language features
- Specific library usage patterns (e.g., swift-parsing, Yams)
- Type system utilization (enums, structs, classes)
- Language-specific error handling patterns
- Platform-specific APIs and operations
- Testing framework integration
- Performance optimization techniques specific to the language
- Build system and package manager configuration

### Keep in Functional Spec (WHAT Only):
- **Capabilities** the system provides
- **Benefits** users receive
- **Use cases** enabled
- **Error handling approach** (not specific methods)
- **Performance characteristics** (not optimization techniques)
- **Integration patterns** (not implementation details)

This three-way separation ensures:
- **Functional specifications** remain focused on value and capabilities
- **Generic code generation specifications** provide universal algorithmic guidance
- **Language-specific implementation guides** enable optimal language-tailored implementations

The layered approach maximizes reusability while ensuring each specification serves its intended audience effectively.
