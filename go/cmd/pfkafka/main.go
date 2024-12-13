package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"time"

	"github.com/segmentio/kafka-go"
	"github.com/segmentio/kafka-go/sasl/plain"
)

func main() {
	// to consume messages
	topic := ""
	user := ""
	pass := ""
	broker := ""
	if len(os.Args) != 5 {
		panic("Not enough args")
	}
	broker = os.Args[1]
	user = os.Args[2]
	pass = os.Args[3]
	topic = os.Args[4]
	fmt.Fprintf(os.Stderr, "listening to %s on %s\n", topic, broker)

	mechanism := plain.Mechanism{
		Username: user,
		Password: pass,
	}

	dialer := &kafka.Dialer{
		Timeout:       10 * time.Second,
		DualStack:     true,
		SASLMechanism: mechanism,
	}
	//      partition := 0
	r := kafka.NewReader(kafka.ReaderConfig{

		Brokers:  []string{broker},
		Topic:    topic,
		GroupID:  "consumer-group-id" + topic,
		MaxBytes: 10e6, // 10MB
		Dialer:   dialer,
	})

	defer func() {
		if err := r.Close(); err != nil {
			log.Fatal("failed to close reader:", err)
		}
	}()

	for {
		m, err := r.ReadMessage(context.Background())
		if err != nil {
			fmt.Printf("Error: %s", err)
			break
		}
		//fmt.Printf("message at offset-partition %d-%d: %s = %s\n", m.Offset, m.Partition, string(m.Key), string(m.Value))
		fmt.Printf("%s\n", string(m.Value))
	}

}
